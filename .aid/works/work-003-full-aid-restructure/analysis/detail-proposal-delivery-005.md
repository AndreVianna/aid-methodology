# Detail proposal -- delivery-005: The four KB skills on one KB state file (Feature 004, first part)

This is `aid-detail` FIRST-RUN for **delivery-005**, under Q136. Decisions are settled by recommendation,
the task files are written at once, and the light review is the check.

- **Source of truth.** The task files under `deliveries/delivery-005/tasks/` are the source of truth. The
  task blocks in § 3 are rendered from the same data as those files.
- **Numbering** continues from delivery-004's task-103.
- **General rules.** The rules G1-G6 from the light reviews of deliveries 001-004 are applied here from the
  start.

**Inputs read:**
- the delivery-005 and delivery-006 stanzas of `PLAN.md`, with the Q117 split of Feature 004;
- `REQUIREMENTS.md` § 11 Feature 004 (all eight subsections);
- the delivery-001 to delivery-004 task files.

**Measured at base `a3b28db4`:**
- `aid-discover` has 19 files and `aid-update-kb` has 8. `aid-ask` is a single `SKILL.md`.
- 52 files under `canonical/` and in `dashboard/home.html` name `.aid/knowledge/STATE.md`.
- The format carriers read 5 in `bin/aid`, `lib/AidInstallCore.psm1` and the settings template.
- `summarize/` holds 16 scripts.
- Eight of the KB-writing `create`/`update` skills, and `design-lifecycle.md`, name a retiring KB skill.
  The rest of the Feature 004 retirements are delivery-006's.

---

## 1. The tasks at a glance

| Task | Title | Type | Stanza wave | Derived wave | Depends on |
|---|---|---|---|---|---|
| task-104 | Delivery-005 site search and reconciled edit list | RESEARCH | 1 | 1 | -- |
| task-105 | KB state template and the work's kb_updates key | IMPLEMENT | 2 | 2 | task-104 |
| task-106 | KB view renderer render-kb-view.sh: page, inputs and determinism | IMPLEMENT | 2 | 2 | task-104 |
| task-107 | build-kb-index.sh without timestamps | IMPLEMENT | 2 | 2 | task-104 |
| task-108 | Root package.json and the view's Playwright CI steps removed | CONFIGURE | 4 | 2 | task-104 |
| task-109 | KB settings keys retired: knowledge.source, knowledge.last_update, complexity-score | IMPLEMENT | 4 | 2 | task-104 |
| task-110 | Writer: the --kb target, the KB modes and --kb-update-log | IMPLEMENT | 2 | 3 | task-105 |
| task-111 | KB view renderer: At a Glance, the three card types and the Markdown export | IMPLEMENT | 2 | 3 | task-106 |
| task-112 | Format 6: the carriers, STEP 0 and the suites that assert format 5 | IMPLEMENT | 4 | 3 | task-105 |
| task-113 | Dashboard readers: the KB state file, the legacy block and the new waterfall | IMPLEMENT | 4 | 3 | task-105 |
| task-114 | Unit cases: test-build-kb-index.sh | TEST | 5 | 3 | task-107 |
| task-115 | KB commit script kb-commit.sh | IMPLEMENT | 2 | 4 | task-110 |
| task-116 | aid-kb-build: the move, START, ELICIT and GENERATE | IMPLEMENT | 3 | 4 | task-105, task-110 |
| task-117 | aid-kb-update: the move, START, ANALYZE, SCOPE, CONFIRM and sweep | IMPLEMENT | 3 | 4 | task-110 |
| task-118 | skill-steps.md: the KB build record and the two KB approval rows; the protocol's Where bullet | IMPLEMENT | 3 | 4 | task-110 |
| task-119 | aid-kb-query and aid-kb-show | IMPLEMENT | 3 | 4 | task-110, task-111 |
| task-120 | Format 6: the KB conversion step, in bash and PowerShell | IMPLEMENT | 4 | 4 | task-112 |
| task-121 | Dashboard KB card texts | IMPLEMENT | 4 | 4 | task-113 |
| task-122 | Writer unit cases: the KB modes | TEST | 5 | 4 | task-110 |
| task-123 | aid-kb-build: REVIEW, QUESTIONS, FIX, APPROVE and FINISH | IMPLEMENT | 3 | 5 | task-107, task-111, task-115, task-116 |
| task-124 | aid-kb-update: APPLY, REVIEW and FINISH | IMPLEMENT | 3 | 5 | task-107, task-111, task-115, task-117, task-118 |
| task-125 | Orchestration, brainstorm and rules.md for the KB skills | IMPLEMENT | 3 | 5 | task-116, task-117, task-118 |
| task-126 | Unit cases: test-kb-commit.sh | TEST | 5 | 5 | task-115 |
| task-127 | Unit cases: test-kb-state-migration.sh (the KB step) | TEST | 5 | 5 | task-120 |
| task-128 | Dashboard cases: KB statuses, Growing, legacy STATE.md, waterfall and cards | TEST | 5 | 5 | task-121 |
| task-129 | Re-point the skills and agents to the KB skills and STATE.yml | IMPLEMENT | 4 | 6 | task-116, task-117, task-118, task-119, task-123, task-124 |
| task-130 | Re-point the templates, scripts, catalog rows and dashboard page | IMPLEMENT | 4 | 6 | task-116, task-117, task-119, task-123, task-124 |
| task-131 | aid-summarize retired, with summarize/ and its suites | IMPLEMENT | 4 | 7 | task-108, task-111, task-123, task-124, task-129, task-130 |
| task-132 | aid-housekeep retired, with its scripts and suites | IMPLEMENT | 4 | 8 | task-117, task-131 |
| task-133 | Unit cases: test-render-kb-view.sh | TEST | 5 | 8 | task-111, task-131 |
| task-134 | test-kb-skills.sh group K1 | TEST | 5 | 9 | task-121, task-125, task-129, task-130, task-131, task-132 |
| task-135 | Samples 004-01, 004-02, 004-03, 004-04 and 004-07 (run at this gate) | TEST | 5 | 9 | task-125, task-131, task-132 |
| task-136 | KB decisions, schemas, glossary, quality gates, tech debt and backlog for the KB skills | DOCUMENT | 4 | 9 | task-110, task-118, task-131, task-132 |
| task-137 | KB architecture, navigation and toolchain documents for the KB skills | DOCUMENT | 4 | 9 | task-108, task-113, task-125, task-131, task-132 |
| task-138 | The four new suites in the CI lane | CONFIGURE | 5 | 10 | task-126, task-127, task-133, task-134 |
| task-139 | KB test landscape for the KB suites, and the regenerated index | DOCUMENT | 5 | 11 | task-114, task-122, task-128, task-135, task-136, task-137, task-138 |

That is 36 tasks. The resync follows task-139. It converts this repository's KB and renders `kb.html`
(§ 4).

---

## 2. Rules every task carries

Each task file carries the blocks of the earlier deliveries, with the general rules G1-G6 from their
light reviews:

- the Execution protocol;
- the same-task rule (Q106) and its ledger rows;
- the findings bullet (`research/delivery-005-sites.md`);
- the standard test step, with step 5's site `npm test` for any change under `canonical/skills/`,
  `canonical/agents/` or `canonical/aid/templates/` (G5);
- **for every IMPLEMENT task:**
  - site regeneration, including the generators' hard-coded counts (G1);
  - the hand check of later static patterns over its own files (G3);
- **for every move or deletion:** the suites that read what it removes, built from a grep of its path and
  folder (G6);
- **in the research task:** the "baseline, re-recorded at the gate" owner class, and a skill owner table
  built from a full listing (G2).

Every needed order is a dependency edge (G4). No task carries a "build first" note.

The moved and new skills (task-116, task-117, task-119) update their lists and counts in the same task:
- the guide line;
- the description;
- the SG-04 exempt rows of the old names;
- a `skill:` row in `deferred.tsv` under the new name, until task-135's samples land;
- the site lists;
- the counted phrases.

---

## 3. Tasks

`Source` reads `feature-004-kb-management -> delivery-005 -> AC-...`.

### task-104: Delivery-005 site search and reconciled edit list [RESEARCH]

- **Stanza wave:** 1. **Depends on:** --.
- **Source:** AC-15, AC-25.
- **Scope:**
  - Create `.aid/works/work-003-full-aid-restructure/research/delivery-005-sites.md`. Touch nothing else.
  - Re-run these searches at this task's base commit, and record the base commit in the file
    (REQUIREMENTS.md § 11 Feature 004 `##### 7. Migration`):
    - **K1** the retired names `aid-discover`, `aid-ask`, `aid-update-kb`, `aid-summarize` and
      `aid-housekeep`, over every kept file under `canonical/`, `dashboard/`, `tests/`, `site/scripts/`,
      `.github/` and `.aid/knowledge/`;
    - **K2** the moved references by their old paths: `aid-discover/references/...`,
      `aid-update-kb/references/...` and `aid-ask/`;
    - **K3** `.aid/knowledge/STATE.md`, and the KB `STATE.md` vocabulary (`summary_approved`,
      `kb_baseline`, `## Q&A (Pending)`, `## Summarization History`);
    - **K4** `AID_SUPPORTED_FORMAT`, `AidSupportedFormat` and `format_version: 5`, plus every suite that
      asserts format 5;
    - **K5** the readers of `knowledge.source`, `knowledge.last_update` and KB state in `complexity-score.sh`;
    - **K6** the summarize and housekeep scripts, suites and CI steps (`test.yml`, `release.yml`, the root
      `package.json`, `.github/dependabot.yml`);
    - **K7** the Q106 suite map for every file on the edit list, including the dashboard KB tests and
      fixtures and the site's skill lists;
    - **K8** the rows of `deferred.tsv`, the SG-04 exempt list and `test-never-merges.sh` (NM-03) that
      name a retiring or moving skill.
  - Give each hit exactly one owner:
    - a task of delivery-005 (task-105 to task-139; see
      `.aid/works/work-003-full-aid-restructure/analysis/detail-proposal-delivery-005.md`);
    - delivery-006 (the KB `create`/`update` skills, `design-lifecycle.md`);
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
  - [ ] Each of K1-K8 shows its exact command, and re-running it at the base named in the file reproduces its hits.
  - [ ] Every hit has exactly one owner; the count of rows with an empty owner cell is 0.
  - [ ] The skill owner table has exactly one row per `canonical/skills/*/SKILL.md` on disk at the base (the row count equals `ls canonical/skills/*/SKILL.md | wc -l`), and no row is unowned.
  - [ ] RESEARCH defaults are overridden as in task-001; the test step selects nothing (work folder only).

### task-105: KB state template and the work's kb_updates key [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-104.
- **Source:** AC-15.
- **Scope:**
  - Create `canonical/aid/templates/kb-state-template.yml` with the keys, `[W]` comments and defaults of
    REQUIREMENTS.md § 11 Feature 004 `##### 2. The KB state file`, in block style.
  - `canonical/aid/templates/work-state-template.yml` gains `kb_updates: []` with its `[W]` comment.
    `pipeline.parent_branch` is delivery-006's.
  - `tests/canonical/test-skill-steps.sh` SS-14 (b) adds `kb-state-template.yml` to its template
    exceptions (`##### 5. Components`, The KB build record). It is updated here because the new template
    carries `active_skill:` and `step:` lines.
  - `discovery-state-template.md` stays until task-116 moves its last user.
  - Suites to update in this same task: `test-work-state-template.sh`, `test-skill-steps.sh`, and any suite
    the findings' K7 assigns here.
- **Acceptance criteria:**
  - [ ] Both templates parse through `dashboard/reader/state_schema.py` and `dashboard/server/reader.mjs` with no warning (KB-04's first clause).
  - [ ] `kb-state-template.yml` holds exactly the spec's keys, with `status: --`, `active_skill: none`, `user_approved: 'no'` and `elicitation: 'no'`. `test-skill-steps.sh` (groups E and S) passes in the scratch copy.

### task-106: KB view renderer render-kb-view.sh: page, inputs and determinism [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-104.
- **Source:** AC-15.
- **Scope:**
  - Create `canonical/aid/scripts/kb/render-kb-view.sh` (bash, awk, sed, `base64`, and `sha256sum` or
    `shasum`; no Python or Node), as REQUIREMENTS.md § 11 Feature 004 `##### 4. The view` says:
    - its arguments and exits: 2, 4 and 5 when rendering; 0, 1 and 3 for `--check`, which writes nothing;
    - its inputs in order: the document set through `read-setting.sh`, then the other `.aid/knowledge/*.md`
      alphabetically; `INDEX.md`, `README.md` and the state file are not read as sections;
    - the page from `html-skeleton.html`, with `component-css.css` and `lightbox.js` inlined;
    - each section: H1, `summary:` lead, `objective:`, `tags:` pills, `see_also:` links, the body and a
      source line;
    - the Markdown subset rendered after HTML-escaping;
    - the index of documents;
    - output to a temporary file renamed into place;
    - same KB, same bytes, with the `aid-kb-inputs` hash.
  - The At a Glance block, the three card types and the Markdown export are task-111.
  - The kept `knowledge-summary/` templates: `html-skeleton.html`'s `description` and `generator` meta and
    its footer say the page is rendered by `render-kb-view.sh` from `.aid/knowledge/`, with no command to
    run; `lightbox.js`'s header names the renderer (REQUIREMENTS.md § 11 Feature 004 `##### 7. Migration`, Re-pointing).
- **Acceptance criteria:**
  - [ ] On a scratch fixture KB, two renders give identical bytes, and the output has no date, time or absolute path.
  - [ ] `--check` exits 0 after a render, 1 after a document changes, and 3 with no `kb.html`, and writes nothing (its `sha256sum` and the file list are unchanged). A missing template exits 5.
  - [ ] A document holding `<script>` renders it escaped, and no `src` or `href` in the output starts with a scheme or `//`.

### task-107: build-kb-index.sh without timestamps [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-104.
- **Source:** AC-15.
- **Scope:**
  - `canonical/aid/scripts/kb/build-kb-index.sh` drops its embedded timestamps: the time in the
    `AUTO-GENERATED` comment and the `Generated at:` line. The same documents give the same `INDEX.md`
    (tech-debt W4-5).
  - Its header names `/aid-kb-build` and `/aid-kb-update` (REQUIREMENTS.md § 11 Feature 004 `##### 4. The view`).
  - Suites to update in this same task: every suite the findings' K7 assigns that asserts the index's
    header lines.
- **Acceptance criteria:**
  - [ ] Running the script twice on the same `.aid/knowledge/` gives byte-identical output, and `grep -c 'Generated at' ` on the output prints 0.
  - [ ] The suites that read the index's header pass where the test step puts them.

### task-108: Root package.json and the view's Playwright CI steps removed [CONFIGURE]

- **Stanza wave:** 4. **Depends on:** task-104.
- **Source:** AC-15, AC-25.
- **Scope:**
  - Delete the repository-root `package.json`, and its entry in `.github/dependabot.yml`
    (REQUIREMENTS.md § 11 Feature 004 `##### 1. Files and layout`). Their only purpose was the view's Playwright check.
  - `.github/workflows/test.yml` and `release.yml`: the summarize validator steps and comments go.
  - Suites to update in this same task: every workflow-reading suite the findings' K6 or K7 assigns here
    (`test-ascii-only.sh`, `test-ps51-compat.sh`, `test-aid-cli-parity.sh` where they apply).
- **Acceptance criteria:**
  - [ ] `test -e package.json` fails; `grep -c` for `package.json` or `npm` in the root `package-ecosystem` entry of `.github/dependabot.yml` finds no root entry; `grep -c summarize .github/workflows/test.yml .github/workflows/release.yml` totals 0.
  - [ ] The workflow-reading suites pass. No secret is added, and applying the edit twice changes nothing.

### task-109: KB settings keys retired: knowledge.source, knowledge.last_update, complexity-score [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-104.
- **Source:** AC-15.
- **Scope:**
  - `canonical/aid/templates/settings.yml` and `canonical/skills/aid-config/SKILL.md` (the `knowledge`
    row): `knowledge.source` and `knowledge.last_update` are no longer written or read. `doc_set` and
    `term_exclusions` stay (REQUIREMENTS.md § 11 Feature 004 `##### 1. Files and layout`).
  - `canonical/aid/scripts/execute/complexity-score.sh` stops reading KB state for its thresholds and keeps
    its defaults. `aid-execute` `references/state-execute.md` § PD-0 names `.aid/settings.yml`, which it
    already reads.
  - Suites to update in this same task: `test-settings-schema-check.sh`, `test-read-setting.sh`,
    `test-write-setting.sh`, the complexity-score suites, and any suite the findings' K5 or K7 assigns
    here.
- **Acceptance criteria:**
  - [ ] Over the files this task edits (`settings.yml`, `aid-config/SKILL.md`, `complexity-score.sh`, `state-execute.md`), `git grep -nE 'knowledge\.(source|last_update)|last_update:'` finds nothing. The moved KB skills drop their own reads in task-116 and task-117 (G3).
  - [ ] `complexity-score.sh` gives the same score on a fixture with and without `.aid/knowledge/`, and its suites pass.

### task-110: Writer: the --kb target, the KB modes and --kb-update-log [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-105.
- **Source:** AC-15, AC-37.
- **Scope:**
  - `canonical/aid/scripts/execute/writeback-state.sh` (REQUIREMENTS.md § 11 Feature 004 `##### 2. The KB state file`, Writer modes):
    - **The `--kb` target** points `--step`, `--ask`, `--answer`, `--check` and `--repair` at
      `.aid/knowledge/STATE.yml`. `--step --kb` accepts only `--skill aid-kb-build`, and sets
      `status: Building` in the same write.
    - **Only two writes create the file:** `--step --kb`, and `--kb --field Status --value Growing`. Every
      other `--kb` write on a missing file changes nothing and exits 10. The new exit is documented in the
      header.
    - **KB-only modes:** `--kb --field F --value V`; `--kb --doc D --doc-status S [--grade G]`;
      `--kb --review --grade G --notes T`; `--kb --clear-build`. Setting `Approved` clears the record.
    - **`--check --kb`**, with the KB record rules (exit 9).
    - **`--kb-update-log --mode M --docs D --grade G --commit C`** appends to the work's `kb_updates`.
      `refresh` writes `docs` and `grade` as `--`; another mode without them exits 5.
  - The unit cases are task-122.
  - Suites to update in this same task: the existing `test-writeback-state.sh` assertions, and any suite
    the findings' K7 assigns here.
- **Acceptance criteria:**
  - [ ] On a scratch project, `--kb --doc x.md --doc-status Populated` with no state file exits 10 and creates nothing. `--step --kb --skill aid-kb-build --name START` creates the file with `status: Building`.
  - [ ] `--kb --field Status --value Approved` sets `active_skill: none` and `step: --`, and `--kb --field Grade --value Z` exits 4.
  - [ ] `--kb-update-log --mode refresh --commit abc` appends an entry with `docs: --` and `grade: --`, and `--mode change` without `--docs` exits 5. `test-writeback-state.sh` passes live.

### task-111: KB view renderer: At a Glance, the three card types and the Markdown export [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-106.
- **Source:** AC-15.
- **Scope:**
  - `canonical/aid/scripts/kb/render-kb-view.sh` gains (REQUIREMENTS.md § 11 Feature 004 `##### 4. The view`, Page):
    - "At a Glance" first, from `capability-inventory.md`'s `summary:` and first rows, the first
      `domain-glossary.md` terms and the first `decisions.md` titles, each part only when its document
      exists;
    - the glossary, decision and capability cards, with today's anchors: `glossary`, `decisions`,
      `capabilities`, and per item `gloss-<slug>`, `adr-d<N>` and `cap-<slug>`. A document that does not
      match its card structure renders as an ordinary section;
    - the documents' text, frontmatter stripped, embedded base64 in
      `<script type="text/markdown" id="kb-md-export">`.
  - The output stays deterministic: same KB, same bytes.
- **Acceptance criteria:**
  - [ ] On a fixture KB with the three documents, the page has the `glossary`, `decisions` and `capabilities` anchors and one `gloss-`, `adr-d` and `cap-` anchor per item. A malformed `decisions.md` renders as an ordinary section.
  - [ ] The `kb-md-export` block decodes to the documents' text with no frontmatter, and two renders are byte-identical.

### task-112: Format 6: the carriers, STEP 0 and the suites that assert format 5 [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-105.
- **Source:** AC-25.
- **Scope:**
  - Raise the format to 6 in every carrier (REQUIREMENTS.md § 11 Feature 004 `##### 7. Migration`, Format 6): `bin/aid`
    `AID_SUPPORTED_FORMAT`, `bin/aid.ps1` `AidSupportedFormat`, `lib/AidInstallCore.psm1`,
    `lib/aid-install-core.sh`'s default, and `canonical/aid/templates/settings.yml` `format_version`.
  - STEP 0 DETECT accepts `.aid/knowledge/STATE.yml` as an era marker, in both twins.
  - The KB conversion step itself is task-120.
  - Suites to update in this same task (every suite asserting format 5): `test-aid-cli.sh`,
    `test-aid-cli-ps1.sh`, `test-aid-cli-parity.sh`, `test-layout-format-guard.sh`, `test-aid-migrate.sh`,
    `test-aid-migrate-trigger.sh`, `test-aid-migration-stamp.sh`, `test-release-migrate-smoke.sh`,
    `test-registry.sh`, `test-install-provisioning.sh`, `tests/windows/Test-AidInstaller.ps1` (T48c and its
    stamp check), `tests/windows/Test-InstallProvisioning.ps1` (SE1d, SE1e), and any suite the findings'
    K4 lists.
  - Bash and PowerShell output stay byte-identical, PowerShell 5.1-safe and ASCII.
- **Acceptance criteria:**
  - [ ] `git grep -nE 'AID_SUPPORTED_FORMAT=5|AidSupportedFormat *= *5|format_version: 5' -- bin lib canonical` finds nothing.
  - [ ] `test-aid-cli-parity.sh`, `test-aid-migrate.sh` and `test-layout-format-guard.sh` pass in the scratch copy. `test-ps51-compat.sh` and `test-ascii-only.sh` pass live.
  - [ ] STEP 0 on a fixture repository holding only `.aid/knowledge/STATE.yml` detects it as a current-era repository in both twins, with byte-identical output.

### task-113: Dashboard readers: the KB state file, the legacy block and the new waterfall [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-105.
- **Source:** AC-15.
- **Scope:**
  - Both readers, kept equal by the parity tests (REQUIREMENTS.md § 11 Feature 004 `##### 5. Components`, Dashboard):
    - **The state file:** they read `.aid/knowledge/STATE.yml` through the state reader. Today's
      `STATE.md` parse moves inside a `legacy-kb-state: begin` / `end` block, and reads the KB approval
      line, not the summary's.
    - **Fields passed on:**
      - `kb_status`, `kb_grade` and `last_kb_review` come from `status`, `grade` and the newest `reviews`
        entry;
      - `approved`, `step` and `open_questions` are new;
      - `summary_present` stays;
      - `summary_approved`, `last_summary_date`, the KB `source_mode` and `kb_baseline` go.
    - **Status waterfall,** first match wins: `pending`, `generating`, `preparing`, `outdated`,
      `approved`, with `Growing` as the spec says.
    - The `knowledge.last_update` comparison goes, with `git_freshness_check` / its Node twin and
      `parse_kb_baseline` (tech-debt L6).
    - `dashboard/server/server.py` and `server.mjs` pass the new fields to the page.
  - Files: `dashboard/reader/models.py`, `parsers.py`, `derivation.py`, `reader.py`,
    `dashboard/server/reader.mjs`, `server.py`, `server.mjs`.
  - Suites to update in this same task: the existing dashboard KB tests and fixtures (`pt1h-kb-*`,
    `test_task064_kb_status.py`, `test_task066_kb_parity.py`, `test-dashboard-parity-h.sh`), and any suite
    the findings' K7 assigns here. The new fixtures are task-128.
- **Acceptance criteria:**
  - [ ] A `STATE.yml` fixture at `Building` reads `generating` in both readers, and a legacy `STATE.md` fixture still reads its status.
  - [ ] `git grep -nE 'git_freshness_check|parse_kb_baseline|last_update' -- dashboard/reader dashboard/server` finds nothing outside the legacy block.
  - [ ] `test-dashboard-parity.sh` and `test-dashboard-reader.sh` pass live, and `test-dashboard-parity-h.sh` passes in the scratch copy.

### task-114: Unit cases: test-build-kb-index.sh [TEST]

- **Stanza wave:** 5. **Depends on:** task-107.
- **Source:** AC-15.
- **Scope:**
  - Create `tests/canonical/test-build-kb-index.sh` (REQUIREMENTS.md § 11 Feature 004 `##### 8. Testing`): rebuilding gives the same
    `INDEX.md`, with no timestamp line (W4-5). It carries
    `# COVERS: canonical/aid/scripts/kb/build-kb-index.sh`.
- **Acceptance criteria:**
  - [ ] The suite passes, with one case for byte-identical rebuilds and one for the absence of any timestamp line.
  - [ ] Re-adding a timestamp line to a scratch copy of the script fails it. The suite is deterministic and cleans up.

### task-115: KB commit script kb-commit.sh [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-110.
- **Source:** AC-15.
- **Scope:**
  - Create `canonical/aid/scripts/kb/kb-commit.sh`, with every mode except `--new-project`, which is
    delivery-006's (REQUIREMENTS.md § 11 Feature 004 `##### 5. Components`, `kb-commit.sh`):
    - `--message M [--with-settings]`;
    - `--build [--finish] --message M`. `--finish` runs `writeback-state.sh --kb --field Status --value
      Approved` after `git add` and stages the state file; if the commit does not complete, it puts back
      the state file copy taken before that write and exits 6;
    - `git add -- <paths>`, then `git commit --only -- <paths>`, so other staged files stay staged;
    - exits 0, 2, 3, 4 and 6;
    - no push, ever.
  - The unit suite is task-126.
- **Acceptance criteria:**
  - [ ] In a scratch repository with another file staged, `kb-commit.sh --message m` commits only `.aid/knowledge/` paths, and the other file is still staged.
  - [ ] `--build --finish` commits a state file reading `status: Approved`. A commit made to fail (a failing `pre-commit` hook) exits 6, and the state file is byte-identical to before.
  - [ ] `grep -c 'git push' canonical/aid/scripts/kb/kb-commit.sh` prints 0.

### task-116: aid-kb-build: the move, START, ELICIT and GENERATE [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-105, task-110.
- **Source:** AC-15, AC-28, AC-37.
- **Scope:**
  - Move `canonical/skills/aid-discover/` to `canonical/skills/aid-kb-build/` (REQUIREMENTS.md § 11 Feature 004 `##### 1. Files and
    layout` and `##### 3. Flows`).
  - `SKILL.md` is rewritten, at most 150 lines:
    - its step table, as the spec's `/aid-kb-build` table;
    - `skill-steps.md` and `question-protocol.md` cited;
    - the opening check (plan mode, `recon-classify.sh`, a rebuild confirmed with one question);
    - `--reset`, `--grade`, § Targeted Discovery and the state map go;
    - the dispatch-visibility checklist stays as a pointer to `long-wait-protocol.md`.
  - References:
    - new `references/start.md` (at most 120 lines): the rebuild clear (`--kb --clear-build`), the
      existing-KB check moved from `generate.md` Step 0, the domain and the document set, `Domain` and
      `Triage`;
    - `state-elicit.md` becomes `elicit.md`, writing `Elicitation`;
    - `state-generate.md` becomes `generate.md`; its Step 7 goes;
    - `document-expectations.md` loses its `greenfield: true` mode;
    - every state write goes through `--kb`, and every question through `--ask --kb`.
  - The REVIEW to FINISH references are task-123. Their files are renamed here, and only their contents
    change there.
  - Delete `canonical/aid/templates/discovery-state-template.md`, whose last user this was.
  - **Lists and counts that follow a moved or new skill**, in this same task:
    - its `canonical/aid/rules.md` § Skill guide line, with the spec's text (`##### 5. Components`);
    - its `description:` in the spec's what/when shape (the four KB skills are not SG-04-exempt);
    - the old name's rows in the SG-04 exempt list of `tests/canonical/test-skill-guide.sh`;
    - the old name's `skill:` row in `tests/conversation/deferred.tsv`, which becomes a `skill:` row for
      the new name until task-135's samples land (DT-01, SS-09);
    - the site skill lists and their `__tests__`;
    - the counted phrases, if the skill count changes (Q134 D5).
  - Suites to update in this same task: the suites that follow the text into the new skill
    (`test-kb-review-surface.sh`, `test-state-review-surface.sh`, `test-doc-set-*.sh`,
    `test-discovery-doc-ownership.sh`, `test-connector-set-unset-lifecycle.sh`, `test-cutover-no-dangling.sh`,
    and any suite the findings' K1, K2 or K7 assigns here).
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
- **Acceptance criteria:**
  - [ ] `test -d canonical/skills/aid-discover` fails, and `canonical/skills/aid-kb-build/` holds `SKILL.md` of at most 150 lines and `references/start.md`, `elicit.md` and `generate.md`.
  - [ ] Over the skill, `git grep -nE 'STATE\.md|discovery-state-template|--reset|--grade'` finds nothing, and every state write names `--kb`. `git grep -nE 'knowledge\.(source|last_update)'` over the skill finds nothing either (G3).
  - [ ] SG-02, SG-04, DT-01 and SS-09 pass in the scratch copy, and the suites above pass where the test step puts them.

### task-117: aid-kb-update: the move, START, ANALYZE, SCOPE, CONFIRM and sweep [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-110.
- **Source:** AC-15, AC-28.
- **Scope:**
  - Move `canonical/skills/aid-update-kb/` to `canonical/skills/aid-kb-update/` (REQUIREMENTS.md § 11 Feature 004 `##### 1. Files and
    layout` and `##### 3. Flows`).
  - `SKILL.md` is rewritten, at most 120 lines:
    - the spec's step table;
    - always inside a work: Pre-flight ISOLATE goes (its own worktree, the `aid/update-kb-<ts>` branch,
      prompt matching, `.aid/.temp/UPDATEKB_STATE_*.md`);
    - the modes `change`, `sweep` and `refresh` on existing documents.
  - References:
    - new `references/start.md`: reads the work record and the draft through `idea-drafts.sh path`; the
      mode; the No-KB safety net for the called case and its own-job case. The removed-KB check of the
      own-job case is delivery-006's (Q60);
    - `state-analyze.md` becomes `analyze.md`, `state-scope.md` becomes `scope.md`, and `state-confirm.md`
      becomes `confirm.md` (own job: `ASK`; called: no stop);
    - new `references/sweep.md`, from `aid-housekeep/references/state-kb-delta.md` with its conformance
      check.
  - APPLY to FINISH are task-124. `state-apply.md` and `state-review.md` are renamed here
    (`apply.md`, `review.md`); `state-approval.md` and `state-done.md` stay until task-124 merges them.
  - **Lists and counts that follow a moved or new skill**, in this same task:
    - its `canonical/aid/rules.md` § Skill guide line, with the spec's text (`##### 5. Components`);
    - its `description:` in the spec's what/when shape (the four KB skills are not SG-04-exempt);
    - the old name's rows in the SG-04 exempt list of `tests/canonical/test-skill-guide.sh`;
    - the old name's `skill:` row in `tests/conversation/deferred.tsv`, which becomes a `skill:` row for
      the new name until task-135's samples land (DT-01, SS-09);
    - the site skill lists and their `__tests__`;
    - the counted phrases, if the skill count changes (Q134 D5).
  - Suites to update in this same task: `test-update-kb-scope-fidelity.sh`,
    `test-conformance-lane-semantics.sh`, `test-f010-governance-guards.sh`, and any suite the findings'
    K1, K2 or K7 assigns here.
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
- **Acceptance criteria:**
  - [ ] `test -d canonical/skills/aid-update-kb` fails. `SKILL.md` is at most 120 lines, with no worktree or branch creation (`git grep -nE 'worktree add|checkout -b|UPDATEKB_STATE' canonical/skills/aid-kb-update` finds nothing).
  - [ ] `start.md` names the three modes and both No-KB paths. `sweep.md` holds the conformance check: divergences are raised, never overwritten.
  - [ ] The three re-pointed suites pass where the test step puts them, and SG-02, SG-04, DT-01 and SS-09 pass in the scratch copy.

### task-118: skill-steps.md: the KB build record and the two KB approval rows; the protocol's Where bullet [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-110.
- **Source:** AC-15, AC-37.
- **Scope:**
  - `canonical/aid/templates/skill-steps.md` (REQUIREMENTS.md § 11 Feature 004 `##### 5. Components`, The KB build record and
    Approvals):
    - a new § The KB build record after § The work record: its place, its rules and its reach;
    - § When approvals happen gains the two rows (the confirmation before the KB is edited; the KB
      change, with `commit`), coinciding approvals, and calls inside another work as small decisions.
  - `canonical/aid/templates/question-protocol.md`: its "Where" bullet says KB building writes through
    `--ask --kb` / `--answer --kb`.
  - Suites to update in this same task: any suite the findings' K7 assigns here.
- **Acceptance criteria:**
  - [ ] `skill-steps.md` has § The KB build record and both rows; `grep -c 'covers: KB change'` on it prints at least 1 (KB-05's first clause).
  - [ ] `question-protocol.md` names `--ask --kb`, and every pointer in both files resolves under `canonical/aid/` (SR-01).

### task-119: aid-kb-query and aid-kb-show [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-110, task-111.
- **Source:** AC-4, AC-15.
- **Scope:**
  - Move `canonical/skills/aid-ask/` to `canonical/skills/aid-kb-query/` (REQUIREMENTS.md § 11 Feature 004 `##### 3. Flows`):
    - its new name and description;
    - gap capture through the writer (`--ask` in a work; `--ask --kb` otherwise, `category: Knowledge Base`,
      `asked_by: aid-kb-query`), and nothing else written;
    - the update offer, or with no KB the build offer;
    - `allowed-tools: Read Glob Grep Bash Agent`.
  - Create `canonical/skills/aid-kb-show/SKILL.md`, at most 60 lines, with `allowed-tools: Read Glob Bash`.
    It runs `render-kb-view.sh --check`, and answers per the spec's exit table (0, 1 and 3, with the
    `Growing` and no-KB cases). Its refresh offer runs `/aid-kb-update` in `refresh` mode.
  - **Lists and counts that follow a moved or new skill**, in this same task:
    - its `canonical/aid/rules.md` § Skill guide line, with the spec's text (`##### 5. Components`);
    - its `description:` in the spec's what/when shape (the four KB skills are not SG-04-exempt);
    - the old name's rows in the SG-04 exempt list of `tests/canonical/test-skill-guide.sh`;
    - the old name's `skill:` row in `tests/conversation/deferred.tsv`, which becomes a `skill:` row for
      the new name until task-135's samples land (DT-01, SS-09);
    - the site skill lists and their `__tests__`;
    - the counted phrases, if the skill count changes (Q134 D5).
  - Suites to update in this same task: every suite the findings' K1, K2 or K7 assigns to `aid-ask`.
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
- **Acceptance criteria:**
  - [ ] `test -d canonical/skills/aid-ask` fails. The `allowed-tools` lines of `aid-kb-query` and `aid-kb-show` hold no `Write` and no `Edit` (KB-03's first clause).
  - [ ] `aid-kb-show/SKILL.md` is at most 60 lines and covers exits 0, 1 and 3, including the `Growing` message verbatim.
  - [ ] SG-02, SG-04, DT-01 and SS-09 pass in the scratch copy, and `test-doc-counts.sh` passes live with the skill count raised by one.

### task-120: Format 6: the KB conversion step, in bash and PowerShell [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-112.
- **Source:** AC-25.
- **Scope:**
  - `_aid_migrate_repo`'s CONVERT-STATE step and its PowerShell twin gain the KB step of
    REQUIREMENTS.md § 11 Feature 004 `##### 7. Migration`. It runs when `.aid/knowledge/STATE.md` exists and `STATE.yml` does not:
    - **Frontmatter:**
      - `kb_status` becomes `status`: `Approved` stays; anything else becomes `Building` with
        `active_skill: aid-kb-build` and `step: START`;
      - `kb_grade` becomes `grade`;
      - the approval line becomes `user_approved`.
    - **Sections:**
      - Domain, Triage and Elicitation become `domain`, `triage` and `elicitation`;
      - Documents Status rows become `documents`, and Review History rows become `reviews`;
      - each `### Q<N>` becomes a `qa` entry (`Required` becomes `High`).
    - An `Approved` KB gets `active_skill: none` and `step: --`.
    - The summary sections, spot-checks and calibration log are dropped.
    - `STATE.yml` is written and `STATE.md` deleted. A re-run changes nothing.
  - The baselines and parent-branch steps are delivery-006's.
  - Files: `bin/aid`, `bin/aid.ps1`, `lib/aid-install-core.sh`, `lib/AidInstallCore.psm1`, whichever hold
    the step.
  - `tests/windows/Test-AidInstaller.ps1` gains a KB-step case (Q126). Bash and PowerShell output are
    byte-identical, PowerShell 5.1-safe and ASCII.
  - The unit suite is task-127.
- **Acceptance criteria:**
  - [ ] Converting a scratch copy of this repository's `.aid/knowledge/STATE.md` gives a `STATE.yml` that parses through both readers with no warning, and a second run changes nothing (`sha256sum` unchanged).
  - [ ] Bash and PowerShell give byte-identical `STATE.yml` for the same fixture under `pwsh`, and `test-ps51-compat.sh` and `test-ascii-only.sh` pass.
  - [ ] The new `Test-AidInstaller.ps1` case passes under `pwsh` locally (5.1 runs in the Windows lane at G0).

### task-121: Dashboard KB card texts [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-113.
- **Source:** AC-15.
- **Scope:**
  - `dashboard/home.html`'s KB card names no skill, with the texts of REQUIREMENTS.md § 11 Feature 004 `##### 5. Components`,
    Dashboard:
    - pending, including the `Growing` text;
    - generating, with "Waiting for your answer (N)";
    - preparing;
    - ready, showing the document count;
    - outdated.
  - Suites to update in this same task: `dashboard/server/tests/test_index_html.py`, and any page test the
    findings' K7 assigns here.
- **Acceptance criteria:**
  - [ ] The page holds each card text verbatim, and `grep -nE 'aid-(discover|summarize|housekeep|kb-)' dashboard/home.html` finds no skill name in the card.
  - [ ] `python3 -m pytest dashboard/server/tests/test_index_html.py` passes.

### task-122: Writer unit cases: the KB modes [TEST]

- **Stanza wave:** 5. **Depends on:** task-110.
- **Source:** AC-15, AC-37.
- **Scope:**
  - `tests/canonical/test-writeback-state.sh` gains the KB cases of REQUIREMENTS.md § 11 Feature 004 `##### 8. Testing`:
    - only the two creating writes make the file, and any other `--kb` write on a missing file exits 10
      and creates nothing;
    - every KB mode writes its keys;
    - `--clear-build` keeps `status`, the record and `qa`, and resets the rest;
    - `Approved` clears the record;
    - invalid values exit 4;
    - `--check --kb` gives 9 for each missing or inconsistent case, and `--repair --kb` fixes it;
    - `--kb-update-log`, including `refresh` and exit 5;
    - every written file parses through the dashboard reader.
- **Acceptance criteria:**
  - [ ] Each case is a named assertion that passes, and fails when its code path is broken in a scratch copy of the writer.
  - [ ] The cases are deterministic, use temporary fixtures only, and pin `HOME`.

### task-123: aid-kb-build: REVIEW, QUESTIONS, FIX, APPROVE and FINISH [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-107, task-111, task-115, task-116.
- **Source:** AC-15, AC-28, AC-37.
- **Scope:**
  - In `canonical/skills/aid-kb-build/references/` (REQUIREMENTS.md § 11 Feature 004 `##### 3. Flows`, `/aid-kb-build` steps 3-6):
    - `review.md` (renamed from `state-review.md`) and `reviewer-brief.md`: `### What to report` kept;
      reviews through `--kb --review`, and the grade through `--kb --field Grade`;
    - `questions.md` (from `state-q-and-a.md`): `Pending` questions in groups; a skipped one is written as
      open in its document and does not block APPROVE;
    - `fix.md` (from `state-fix.md`);
    - `approve.md` (from `state-approval.md`): one approval in chunks, recorded `--ask --kb --category
      Approval --covers 'KB build'`;
    - `finish.md` (from `state-done.md`): stamp `approved_at_commit:`; regenerate `INDEX.md` and
      `README.md`'s completeness rows; render the view; write `User Approved` and `Baseline`;
      `kb-commit.sh --build --finish`; nothing pushed, plus the one push line; the no-git and failed-commit
      paths.
  - `state-closure.md` is folded or re-pointed as the findings say.
  - Suites to update in this same task: any suite the findings' K2 or K7 assigns to these references.
- **Acceptance criteria:**
  - [ ] `finish.md` runs `kb-commit.sh --build --finish`, `render-kb-view.sh` and `build-kb-index.sh` in that order of steps, and contains no `git push`.
  - [ ] No reference under `canonical/skills/aid-kb-build/` names `STATE.md`, a `state-*.md` file, or a banner form, and every step's `**Advance:**` matches the spec's table.
  - [ ] The suites pass where the test step puts them, and the site `npm test` passes after regeneration.

### task-124: aid-kb-update: APPLY, REVIEW and FINISH [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-107, task-111, task-115, task-117, task-118.
- **Source:** AC-15, AC-17, AC-28.
- **Scope:**
  - In `canonical/skills/aid-kb-update/references/` (REQUIREMENTS.md § 11 Feature 004 `##### 3. Flows`, `/aid-kb-update` steps 4-6):
    - `apply.md`: edits within the confirmed scope only. Creating a new document is delivery-006's
      `new-document.md`;
    - `review.md` and a new `reviewer-brief.md` (with `### What to report`, SS-13): one graded review
      scoped to the changed documents, with the scope-diff guard first, the bar `minimum_grade`, and the
      ledger `.aid/.temp/review-pending/<work>-kb-update.md`;
    - `finish.md` (merging `state-approval.md` and `state-done.md`):
      - stamp the changed documents; regenerate `INDEX.md`; render the view, skipped when the KB holds no
        document; `kb-commit.sh`; `--kb-update-log`;
      - called: an `Assumed` `KB change` entry, then `HALT`;
      - own job: the KB change approval, whose yes runs Feature 003's draft deletion, then `PASS` to the
        close minimum run by `/aid-orchestrate`;
      - `refresh` skips stamping.
- **Acceptance criteria:**
  - [ ] `finish.md` names `idea-drafts.sh`, `--kb-update-log` and the close (KB-05's second clause), and `state-approval.md` and `state-done.md` no longer exist.
  - [ ] `reviewer-brief.md` has `### What to report`. No reference names `STATE.md` or a worktree of its own.
  - [ ] The suites pass where the test step puts them, and the site `npm test` passes after regeneration.

### task-125: Orchestration, brainstorm and rules.md for the KB skills [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-116, task-117, task-118.
- **Source:** AC-14, AC-15.
- **Scope:**
  - `canonical/skills/aid-orchestrate/references/start-or-resume.md` (REQUIREMENTS.md § 11 Feature 004 `##### 5. Components`,
    `/aid-orchestrate`):
    - the build first: with the KB state file at `Building` and a saved step, one question offering to
      finish it;
    - open KB questions: one route whatever the status, answered with `--answer --kb` and applied by status.
    The drift check is delivery-006's.
  - `size-and-route.md`:
    - the Knowledge update row creates the work with `--skill aid-kb-update --step START` and no phase,
      after the KB check: with no KB and code, the build first; at `Building`, finish it first;
    - the Preparation row names `/aid-kb-build`.
    The new-project row is delivery-006's.
  - `feedback-routing.md`: "KB questions -> KB update" names `/aid-kb-update`.
  - `canonical/skills/aid-brainstorm/references/finish.md`: the KB-update hand-off targets `aid-kb-update`,
    offered only when a KB exists; with no KB, "build the KB first" (Components, No KB: one rule).
  - `canonical/aid/rules.md`: the tracking line names `.aid/knowledge/STATE.yml`, and the connectors line
    says connectors are catalogued "when `/aid-kb-build` builds the Knowledge Base". The file names no tool
    folder and no `canonical/` path.
  - Suites to update in this same task: `test-shared-layout-sources.sh`, `test-skill-guide.sh`, and any
    suite the findings' K7 assigns here.
- **Acceptance criteria:**
  - [ ] `start-or-resume.md` holds the build's resume offer and the open-KB-questions route. `size-and-route.md` routes a knowledge update to `aid-kb-update` (KB-06's parts for this delivery).
  - [ ] `rules.md` names `.aid/knowledge/STATE.yml` and `/aid-kb-build` in its connectors line (KB-08), and `test-shared-layout-sources.sh` passes in the scratch copy.
  - [ ] `aid-brainstorm`'s `finish.md` offers the KB update only when a KB exists, and every edited reference stays within 120 lines.

### task-126: Unit cases: test-kb-commit.sh [TEST]

- **Stanza wave:** 5. **Depends on:** task-115.
- **Source:** AC-15.
- **Scope:**
  - Create `tests/canonical/test-kb-commit.sh` on throwaway git fixtures (REQUIREMENTS.md § 11 Feature 004 `##### 8. Testing`), with
    every case except `--new-project`, which is delivery-006's:
    - only KB paths are committed, and another staged file stays staged;
    - `--with-settings` and `--build` add their paths;
    - exit 3 without git, and 4 on a detached head or during a merge, each changing nothing;
    - `--finish` commits a state file marked `Approved`; a commit made to fail exits 6 and leaves the
      state file back at FINISH, byte for byte.
- **Acceptance criteria:**
  - [ ] The suite passes, with a named assertion for each listed case.
  - [ ] It is deterministic, cleans up its fixtures and pins `HOME`.

### task-127: Unit cases: test-kb-state-migration.sh (the KB step) [TEST]

- **Stanza wave:** 5. **Depends on:** task-120.
- **Source:** AC-25.
- **Scope:**
  - Create `tests/canonical/test-kb-state-migration.sh` with the KB-step cases of REQUIREMENTS.md § 11 Feature 004 `##### 8. Testing`:
    - a full `STATE.md` fixture converts to the expected `STATE.yml`;
    - running again changes nothing;
    - STEP 0 accepts a `STATE.yml`-only repository;
    - bash and PowerShell give the same bytes, with the PowerShell half running under `pwsh`.
  - The baselines and parent-branch cases are delivery-006's.
- **Acceptance criteria:**
  - [ ] The suite passes in the scratch copy, with each case named.
  - [ ] Changing one byte of the PowerShell output in a scratch copy fails the byte-identity case, and the suite is deterministic.

### task-128: Dashboard cases: KB statuses, Growing, legacy STATE.md, waterfall and cards [TEST]

- **Stanza wave:** 5. **Depends on:** task-121.
- **Source:** AC-15.
- **Scope:**
  - Add to the dashboard tests (REQUIREMENTS.md § 11 Feature 004 `##### 8. Testing`, Dashboard):
    - fixtures for each KB status, a `Growing` skeleton and a legacy `STATE.md`;
    - the new waterfall;
    - the card texts in `test_index_html.py`;
    - the parity tests (`test_task066_kb_parity.py`, `test-dashboard-parity-h.sh`).
- **Acceptance criteria:**
  - [ ] Both readers give the same status for every fixture, matching the waterfall's first-match order, and the parity tests pass.
  - [ ] `test_index_html.py` asserts each card text, and passes.

### task-129: Re-point the skills and agents to the KB skills and STATE.yml [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-116, task-117, task-118, task-119, task-123, task-124.
- **Source:** AC-15.
- **Scope:**
  - Re-point by one rule (REQUIREMENTS.md § 11 Feature 004 `##### 7. Migration`, Re-pointing) every kept file under
    `canonical/skills/` and `canonical/agents/` that names:
    - a retired skill (`aid-discover`, `aid-ask`, `aid-update-kb`, `aid-summarize`, `aid-housekeep`);
    - a moved reference by its old path;
    - `.aid/knowledge/STATE.md`.
    A descriptive mention is reworded. The gate's legacy block and `canonical/aid/scripts/migrate/` are
    exempt.
  - The KB-writing `aid-create-*` / `aid-update-*` skills are kept files until delivery-006 retires them, so
    their mentions are re-pointed here too (KB-02 has no exemption for them).
  - Named targets:
    - `aid-execute`'s "kb-gap -> targeted /aid-discover" becomes a `CALL` to `/aid-kb-update`;
    - the escalation lines of `aid-architect`, `aid-researcher` and `aid-reviewer` record through `--ask`:
      the work's `qa` in a work; `--ask --kb` otherwise; outside a work with no KB, the agent's report only.
  - Suites to update in this same task: every suite the findings' K1, K2, K3 or K7 assigns to these
    files.
- **Acceptance criteria:**
  - [ ] Over `canonical/skills/` and `canonical/agents/`, `git grep -nE 'aid-(discover|ask|update-kb|summarize|housekeep)\b|knowledge/STATE\.md'` finds only lines in skills task-131 and task-132 delete.
  - [ ] `aid-execute` names `/aid-kb-update` where it named `/aid-discover`, and the three agents' escalation lines name `--ask`.
  - [ ] The suites pass where the test step puts them, and the site `npm test` passes after regeneration.

### task-130: Re-point the templates, scripts, catalog rows and dashboard page [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-116, task-117, task-119, task-123, task-124.
- **Source:** AC-15.
- **Scope:**
  - The same rule (REQUIREMENTS.md § 11 Feature 004 `##### 7. Migration`, Re-pointing) over every kept file under
    `canonical/aid/templates/` and `canonical/aid/scripts/` (except `migrate/`), and over
    `dashboard/home.html` outside the KB card:
    - `connectors/reconcile.md` and `connectors/preset-catalog.md` point at
      `aid-kb-build/references/elicit.md` (Step E2);
    - `kb-authoring/concern-model.md`, `domain-doc-matrix.md`, `frontmatter-schema.md`, `review-rubric.md`
      and `principles.md` point at `.agents/skills/aid-kb-build/references/doc-set-resolve.md`,
      `document-expectations.md` and `review.md`; `principles.md`'s `discover-preflight.sh` mention goes;
    - `work-initiation-gate.md` outside its legacy block, and `design-lifecycle.md` (kept until delivery-006);
    - the rows and comments of `shortcut-catalog.yml` that name a retired or moved skill. The `GENERATED`
      doorway skills change only through `build-shortcut-skills.py`.
  - Suites to update in this same task: `test-shortcut-builder-invariants.sh`, and every suite the
    findings' K1, K2, K3 or K7 assigns to these files.
- **Acceptance criteria:**
  - [ ] Over these files, `git grep -nE 'aid-(discover|ask|update-kb|summarize|housekeep)\b|knowledge/STATE\.md|state-(elicit|generate)\.md'` finds nothing outside the gate's legacy block and `migrate/`.
  - [ ] `python3 .claude/skills/generate-profile/scripts/build-shortcut-skills.py --check` exits 0, and the suites pass where the test step puts them.

### task-131: aid-summarize retired, with summarize/ and its suites [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-108, task-111, task-123, task-124, task-129, task-130.
- **Source:** AC-15.
- **Scope:**
  - Delete `canonical/skills/aid-summarize/` and `canonical/aid/scripts/summarize/`, including
    `summarize/writeback-state.sh` and its scalars (REQUIREMENTS.md § 11 Feature 004 `##### 1. Files and layout`).
    `contrast-check.mjs` moves to `tests/canonical/lib/contrast-check.mjs`.
  - `canonical/aid/templates/knowledge-summary/`: `prompt.md`, `grading-rubric.md`,
    `authored-visual-catalog.md` and `section-templates/` go. The renderer's inputs stay.
  - Retire the summarize suites, with accepted-removal rows: `test-grade-summary.sh`,
    `test-guardrails-d012.sh`, `test-visual-fidelity.sh`, `test-validator-behavior.sh`,
    `test-summarize-preflight.sh`, `test-assemble-3part.sh`, `test-assemble-3part-ps1.sh`,
    `test-assemble-determinism.sh`, `test-diagram-content.sh`, `test-kb-export.sh`,
    `test-kb-export-pw.mjs`, `test-md-export-embed.sh`, `test-kb-html-claims-check.sh`,
    `test-payload-size.sh` and `test-contrast-check.sh`.
  - Lists and counts: its guide line, its rows in `deferred.tsv` and the SG-04 exempt list, and the counted
    phrases (Q134 D5).
  - Update the site skill lists and their `__tests__`.
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
- **Acceptance criteria:**
  - [ ] `test -e canonical/skills/aid-summarize` and `test -e canonical/aid/scripts/summarize` both fail, and `tests/canonical/lib/contrast-check.mjs` exists.
  - [ ] None of the 15 retired suites exists, and each of their assertion ids in `tests/coverage-baseline.tsv` has an accepted-removal row.
  - [ ] SG-02, DT-01 and `test-doc-counts.sh` pass, and the site `npm test` passes after regeneration.

### task-132: aid-housekeep retired, with its scripts and suites [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-117, task-131.
- **Source:** AC-15.
- **Scope:**
  - Delete `canonical/skills/aid-housekeep/`, `canonical/aid/scripts/housekeep/branch-commit.sh`,
    `housekeep-state.sh` and `canonical/aid/scripts/kb/discover-preflight.sh`. `cleanup-classify.sh` stays
    for Feature 008.
  - `tests/canonical/test-never-merges.sh`: NM-03's `aid-housekeep` exemption goes.
  - Retire `test-housekeep-branch-commit.sh`, `test-housekeep-state.sh` and `test-discover-preflight.sh`,
    with accepted-removal rows. The classify, deletion-split and work-folder-safety suites stay, with
    `cleanup-classify.sh`.
  - Lists and counts: its guide line, its rows in `deferred.tsv` and the SG-04 exempt list, and the counted
    phrases.
  - Update the site skill lists and their `__tests__`.
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
- **Acceptance criteria:**
  - [ ] `test -e canonical/skills/aid-housekeep` fails, `canonical/aid/scripts/housekeep/cleanup-classify.sh` exists, and `test-never-merges.sh` passes with only the `aid-execute` exemption firing.
  - [ ] The retired suites are gone with their accepted-removal rows, and the classify suites pass.
  - [ ] SG-02, DT-01 and `test-doc-counts.sh` pass, and the site `npm test` passes after regeneration.

### task-133: Unit cases: test-render-kb-view.sh [TEST]

- **Stanza wave:** 5. **Depends on:** task-111, task-131.
- **Source:** AC-15.
- **Scope:**
  - Create `tests/canonical/test-render-kb-view.sh` on a fixture KB, with every case of
    REQUIREMENTS.md § 11 Feature 004 `##### 8. Testing`:
    - rendering twice gives identical bytes, with no date or time;
    - a section per document in the fixed order, with the three card types;
    - a document that matches no card structure still renders;
    - markup is escaped;
    - each Markdown form renders, and an unknown one shows as text;
    - no `src` or `href` starts with a scheme or `//`;
    - landmarks, the language and the skip link are present;
    - the palette's contrast passes `tests/canonical/lib/contrast-check.mjs`;
    - `--check` returns 0, 1 and 3, and writes nothing;
    - a missing template exits 5.
- **Acceptance criteria:**
  - [ ] The suite passes, with a named assertion for each case.
  - [ ] It is deterministic and needs no network. The Node contrast check runs with the standard library only.

### task-134: test-kb-skills.sh group K1 [TEST]

- **Stanza wave:** 5. **Depends on:** task-121, task-125, task-129, task-130, task-131, task-132.
- **Source:** AC-15.
- **Scope:**
  - Create `tests/canonical/test-kb-skills.sh`, group K1, as REQUIREMENTS.md § 11 Feature 004 `##### 8. Testing` defines it:
    - KB-01 and KB-02, for this delivery's names: the four skills exist; `aid-discover`, `aid-ask`,
      `aid-update-kb`, `aid-summarize`, `aid-housekeep`, `summarize/` and `discovery-state-template.md` are
      absent and named nowhere outside the exemptions;
    - KB-03;
    - KB-04;
    - KB-05;
    - KB-06, for the build resume and the knowledge-update routing;
    - KB-08.
    It has `# COVERS:` lines and a group filter. The KB `create`/`update` names, the drift check, the new
    project, the backlog and KB-07 are delivery-006's group K2.
- **Acceptance criteria:**
  - [ ] The suite passes in the scratch copy.
  - [ ] Each check fails its own mutation in a scratch copy: a `canonical/skills/aid-discover/` folder; a line naming `aid-ask/` in a kept file; `Write` in `aid-kb-show`'s tools; a kept file naming `.aid/knowledge/STATE.md`; a missing KB-change row; `size-and-route.md` without `aid-kb-update`; `rules.md` without `/aid-kb-build`.
  - [ ] It is deterministic and finishes within the 300-second budget.

### task-135: Samples 004-01, 004-02, 004-03, 004-04 and 004-07 (run at this gate) [TEST]

- **Stanza wave:** 5. **Depends on:** task-125, task-131, task-132.
- **Source:** AC-4, AC-14, AC-15, AC-28, AC-37.
- **Scope:**
  - Create `tests/conversation/samples/feature-004/` with `004-01-build-from-code`,
    `004-02-build-resumed-by-another-user`, `004-03-question-the-kb-lacks`, `004-04-fact-stated` and
    `004-07-show-the-view`, and their fixtures, with the checks of REQUIREMENTS.md § 11 Feature 004 `##### 8. Testing`.
  - Update `tests/conversation/deferred.tsv`:
    - the `skill:` rows for `aid-kb-build`, `aid-kb-query`, `aid-kb-update` and `aid-kb-show` go, since
      these samples now cover them;
    - `002-13` waits only for Feature 007.
    `003-11` keeps its row until delivery-006 runs it (PLAN.md delivery-006 gate).
  - Smoke run (Q134 D8): each sample once, in a scratch copy.
- **Acceptance criteria:**
  - [ ] There are five files, and each `covers` matches the spec's sample table. No `## Answer sheet` names a skill.
  - [ ] DT-01 and SS-09 pass, with no `skill:aid-kb-*` row left.
  - [ ] Each sample has had one smoke run, with its result reported.

### task-136: KB decisions, schemas, glossary, quality gates, tech debt and backlog for the KB skills [DOCUMENT]

- **Stanza wave:** 4. **Depends on:** task-110, task-118, task-131, task-132.
- **Source:** AC-15, AC-24.
- **Scope:**
  - Edit these documents under `.aid/knowledge/` (REQUIREMENTS.md § 11 Feature 004 `##### 7. Migration`, KB and Release notes), for
    this delivery's part:
    - `decisions.md`: the new decision "the Knowledge Base keeps itself current: four skills, writes only
      inside works, a script-rendered view". It amends D18 and D28's consequence, both marked;
    - `artifact-schemas.md`: the KB state file, `kb_updates` and the view;
    - `domain-glossary.md`: Preparation, KB build, update, query, show, web view and drift; summarize,
      housekeep and the KB `STATE.md` vocabulary go;
    - `quality-gates.md`: the two-grade view rubric goes;
    - `tech-debt.md`: L6, SY-7, W4-5 and the view half of W1-11 are resolved (G-03); SY-1 moves with
      `cleanup-classify.sh`;
    - `backlog.md` § Next Release: the old -> new rows for `/aid-discover`, `/aid-ask`, `/aid-update-kb`,
      `/aid-summarize` and `/aid-housekeep` (AC-24).
  - The `create`/`update` rows, `roadmap.md` and the `authoring-conventions.md` `state` row are
    delivery-006's (proposal S6).
  - Name no work and no work folder.
- **Acceptance criteria:**
  - [ ] The five backlog rows carry the spec's New text, and D18 and D28 are marked in the summary table and in their sections.
  - [ ] L6, SY-7 and W4-5 leave no trace. No work id, and the citation and frontmatter lints pass.

### task-137: KB architecture, navigation and toolchain documents for the KB skills [DOCUMENT]

- **Stanza wave:** 4. **Depends on:** task-108, task-113, task-125, task-131, task-132.
- **Source:** AC-15.
- **Scope:**
  - Edit these documents under `.aid/knowledge/`, for this delivery's part:
    - `architecture.md`, `capability-inventory.md`, `module-map.md` and `pipeline-contracts.md`: Discover
      becomes Preparation, and the KB loop;
    - `project-structure.md`;
    - `infrastructure.md` and `integration-map.md`;
    - `technology-stack.md`: Playwright and the root `package.json` go.
  - Name no work and no work folder.
- **Acceptance criteria:**
  - [ ] Over the edited documents, `git grep -nE 'aid-(discover|ask|update-kb|summarize|housekeep)\b'` finds nothing outside marked history, and `technology-stack.md` names no Playwright step.
  - [ ] No work id, and the lints pass. Each statement matches `canonical/` as task-132 leaves it.

### task-138: The four new suites in the CI lane [CONFIGURE]

- **Stanza wave:** 5. **Depends on:** task-126, task-127, task-133, task-134.
- **Source:** AC-25.
- **Scope:**
  - `.github/workflows/installer-tests.yml`: the bash-harness `SUITES` list gains `test-kb-skills`,
    `test-render-kb-view`, `test-kb-commit` and `test-kb-state-migration`.
  - Suites to update in this same task: the workflow-reading suites, where they assert the workflow's
    text.
- **Acceptance criteria:**
  - [ ] Each name appears once in `SUITES`, and applying the edit twice changes nothing.
  - [ ] The lane loop over `SUITES` exits 0 in the scratch copy, and no secret is added.

### task-139: KB test landscape for the KB suites, and the regenerated index [DOCUMENT]

- **Stanza wave:** 5. **Depends on:** task-114, task-122, task-128, task-135, task-136, task-137, task-138.
- **Source:** AC-15, AC-25.
- **Scope:**
  - `.aid/knowledge/test-landscape.md`: the new suites (`test-kb-skills.sh` K1, `test-render-kb-view.sh`,
    `test-kb-commit.sh`, `test-kb-state-migration.sh`, `test-build-kb-index.sh`) and their lane; the
    retired summarize and housekeep suites go.
  - Then regenerate `INDEX.md`. `kb.html` is rendered at this delivery's resync step, after the conversion
    (PLAN.md delivery-005, wave 5).
  - Name no work and no work folder.
- **Acceptance criteria:**
  - [ ] `test-landscape.md` names the five new suites, and none of the retired ones.
  - [ ] `INDEX.md` is regenerated; no work id, and the lints pass.

---

## 4. Coverage, and steps that are not tasks

| Stanza item / gate criterion | Task(s) |
|---|---|
| Skill moves and the new skill | 116, 123 (kb-build); 117, 124 (kb-update); 119 (kb-query, kb-show) |
| `render-kb-view.sh`, `kb-commit.sh`, `build-kb-index.sh` without timestamps | 106, 111; 115; 107 |
| `kb-state-template.yml`, the `--kb` modes, `--kb-update-log`, `kb_updates` | 105; 110 |
| The KB build record and two approval rows; the protocol's "Where" bullet | 118 |
| Retired: summarize, housekeep, their scripts, `discover-preflight.sh`, `knowledge-summary/` parts, root `package.json` and CI steps; the NM-03 exemption | 131, 132, 108 |
| Format 6: the carriers, STEP 0, the KB step in both twins, the `Test-AidInstaller.ps1` case, the format-5 suites | 112, 120 |
| Dashboard: `STATE.yml`, the legacy block, the waterfall with `Growing`, the KB card; settings keys and `complexity-score.sh` | 113, 121; 109 |
| Orchestration: build resume, open KB questions, knowledge-update routing with the build first, feedback routing, brainstorm's KB branch, the `rules.md` lines | 125 |
| Re-pointing of every retired or moved name of this part | 129, 130 (and each move task's own files) |
| Suites: K1, `test-render-kb-view.sh`, `test-kb-commit.sh`, `test-kb-state-migration.sh`, `SUITES` | 134, 133, 126, 127, 138; also 114, 122, 128 |
| Gate: samples `004-01`, `004-02`, `004-03`, `004-04`, `004-07` | 135 |
| G0: AC-24 rows; KB; `INDEX.md` | 136; 136, 137, 139 |

**Steps that are not tasks:**
1. `--delivery-id 005 --lifecycle Executing`.
2. The tasks.
3. Verification.
4. The resync (`delivery-005: resync`):
   - `aid update` runs format 6's KB step on this repository, converting `.aid/knowledge/STATE.md` to
     `STATE.yml`;
   - the retired skills leave through the manifest;
   - `kb.html` is then rendered with the installed `render-kb-view.sh` (PLAN wave 5).
5. The gate, in a new session:
   - the stanza's criteria;
   - this repository's `render-kb-view.sh --check` exits 0;
   - the five samples at 3 of 3, and `001-05` and `001-15` again;
   - G0 with the baselines;
   - the tracking proof for task-104 to task-139.

---

## 5. Execution graph

`derive-waves.sh --from-tasks` derives the following from the written task files:

```text
wave 1: task-104
wave 2: task-105, task-106, task-107, task-108, task-109
wave 3: task-110, task-111, task-112, task-113, task-114
wave 4: task-115, task-116, task-117, task-118, task-119, task-120, task-121, task-122
wave 5: task-123, task-124, task-125, task-126, task-127, task-128
wave 6: task-129, task-130
wave 7: task-131
wave 8: task-132, task-133
wave 9: task-134, task-135, task-136, task-137
wave 10: task-138
wave 11: task-139
```

Step 5 writes each delivery's table under `### delivery-005 Execution Graph`, one task per row. It builds
the table from the task files' `**Depends on:**` lines, never from this proposal.

---

## 6. Settled by recommendation (Q136)

| # | Point | Settled as | Basis |
|---|---|---|---|
| S1 | The renderer, `aid-kb-build` and `aid-kb-update` are each too big for one review. | Each is split in two: the renderer's page vs its cards (106, 111); kb-build's move with START to GENERATE vs REVIEW to FINISH (116, 123); kb-update's move with START to CONFIRM and sweep vs APPLY to FINISH (117, 124). | One session and one review per task. |
| S2 | A move breaks SG-02, SG-04, DT-01 and SS-09 unless the lists move with it. | Each move task carries its lists. A new name gets a temporary `skill:` row until task-135's samples cover it. | Same-task rule; DT-01 and SS-09. |
| S3 | Format 6 in two twins. | The carriers and STEP 0 in both twins first (112), then the KB step in both twins with the Windows case (120). Twins are never split, so parity holds at every task's end. | AC-25; the parity suites. |
| S4 | The KB-writing `create`/`update` skills and `design-lifecycle.md` survive until delivery-006, but name retiring KB skills. | They are re-pointed here (129, 130), as kept files under the re-pointing rule. KB-02 has no exemption for them. | F004 § 7, Re-pointing. |
| S5 | `004-05`, `004-06`, `004-08` and `004-09` are "now" in the spec, but need delivery-006's parts (drift check, backlog). | They are written and run in delivery-006, as its gate says. `003-11` keeps its row until then. | PLAN delivery-006 gate. |
| S6 | The `authoring-conventions.md` `state` row and G-04 retire "since this was the last in-scope `STATE.md`". This repository's `.aid/knowledge/STATE.md` is converted only at this delivery's resync. | The edit moves to delivery-006's KB task, so the registry never untypes a file still on disk. `roadmap.md` § MVP also waits for delivery-006, when the roadmap, MVP and backlog skills retire. | G-07; Q117 split. |
| S7 | Rendering `kb.html`. | At the resync step, as the plan says, not in a task. Nothing changes a KB document after task-139. | PLAN delivery-005 wave 5. |
| S8 | Unit cases and samples are TEST tasks; samples get one smoke run; `test-landscape.md` comes last. | As in the earlier deliveries. | Q134 D2 and D8; Q135 R1 and R3. |

---

## 7. Flagged for the maintainer

None.
