# Detail proposal -- delivery-004: Shape an idea into a draft that survives (Feature 003)

> **Superseded by the task files.** After the light-review fixes (general rules G1-G6, Q137), the
> dependencies, scopes and criteria in this proposal's tables, task blocks and execution graph no longer
> match the task files. The task files under `deliveries/delivery-004/tasks/` are the source of truth. Step 5
> builds PLAN.md's Execution Graph from their `**Depends on:**` lines, never from this proposal.

This is `aid-detail` FIRST-RUN for **delivery-004**, under Q136. Decisions are settled by recommendation,
the task files are written at once, and the light review after the delivery is the check. Numbering
continues from delivery-003's task-081.

**Inputs read:**
- the delivery-004 stanza of `PLAN.md`;
- `REQUIREMENTS.md` § 11 Feature 003 (§§ 1-7 and Criteria traceability);
- Feature 005's and Feature 006's legacy-row and migration text, for one cross-check (§ 7, F-1);
- KI-004;
- the delivery-001 to delivery-003 task files.

**Measured at base `a3b28db4`:**
- 49 files under `canonical/`, outside the retiring skills, name `aid-describe` or `aid-design`; so do 10
  suites (besides the baselines) and 14 site-script files.
- The shortcut catalog has 22 `verb: design` rows.
- `aid-describe` has 13 references.
- This work's own `pipeline.initiator` is `aid-describe` (see F-1).

Anchors read as in the earlier proposals. "F003 § 2" is Feature 003's `##### 2. The idea draft`.

---

## 1. The tasks at a glance

| Task | Title | Type | Stanza wave | Derived wave | Depends on |
|---|---|---|---|---|---|
| task-082 | Delivery-004 site search and reconciled edit list | RESEARCH | 1 | 1 | -- |
| task-083 | Draft script `idea-drafts.sh` | IMPLEMENT | 2 | 2 | 082 |
| task-084 | Writer fields `Idea Draft` and `Side Idea`, and their template keys | IMPLEMENT | 2 | 2 | 082 |
| task-085 | Kind catalog `kind-catalog.yml` (v1) | IMPLEMENT | 2 | 2 | 082 |
| task-086 | Idea-draft shape and the design-folder README | IMPLEMENT | 2 | 2 | 082 |
| task-087 | `/aid-brainstorm` rewrite: the skill, START and CONVERSE | IMPLEMENT | 3 | 3 | 083, 084, 085, 086 |
| task-088 | The draft deletion rule and the gate's two legacy rows | IMPLEMENT | 3 | 3 | 083, 084 |
| task-089 | `/aid-orchestrate` routing rows and the kind hook | IMPLEMENT | 3 | 3 | 083, 085 |
| task-090 | `/aid-brainstorm` rewrite: CHECK, FINISH, parking and side ideas | IMPLEMENT | 3 | 4 | 087 |
| task-091 | Re-point the skills that name `/aid-describe` or `/aid-design` | IMPLEMENT | 4 | 4 | 087 |
| task-092 | Re-point the templates and scripts; trim `design-lifecycle.md` | IMPLEMENT | 4 | 4 | 087, 088 |
| task-093 | `/aid-describe` retired | IMPLEMENT | 4 | 5 | 088, 090, 091, 092 |
| task-094 | `/aid-design` and every `/aid-design-<kind>` retired | IMPLEMENT | 4 | 6 | 089, 093 |
| task-095 | Unit cases: `test-idea-drafts.sh` | TEST | 5 | 3 | 083 |
| task-096 | Unit cases: the writer fields and the new legacy-row fixtures | TEST | 5 | 4 | 084, 088 |
| task-097 | KB decisions, backlog, roadmap, tech debt and schemas for idea drafts | DOCUMENT | 4 | 7 | 088, 094 |
| task-098 | KB architecture and navigation documents for idea drafts | DOCUMENT | 4 | 7 | 089, 094 |
| task-099 | `test-idea-shaping.sh` (ID-01 to ID-07) and the exempt codes | TEST | 5 | 7 | 085, 086, 090, 092, 094 |
| task-100 | Samples `003-01` to `003-05` (run at this gate) | TEST | 5 | 7 | 089, 090, 094 |
| task-101 | Samples `003-06` to `003-11` and the deferred list | TEST | 5 | 8 | 100 |
| task-102 | The two new suites in the CI lane | CONFIGURE | 5 | 8 | 095, 099 |
| task-103 | KB test landscape for the idea suites, and the regenerated index | DOCUMENT | 5 | 9 | 097, 098, 101, 102 |

That is 22 tasks. The resync follows task-103, and `001-08` is re-run at the gate (§ 4).

---

## 2. Rules carried forward

Every task file carries delivery-003's blocks:
- the Execution protocol note;
- the same-task rule (Q106) and its ledger rows;
- the findings bullet, which names `research/delivery-004-sites.md`;
- site regeneration wherever skill text changes;
- the standard test step, with step 5's `node --test`.

The retirements (task-093 and task-094) also apply these rules in the same task:
- the count re-sync of Q134 D5. This delivery removes 23 skills;
- each lists' rows for the retired skills leave with their skill (DT-01 and the exempt lists fail on a
  missing folder): `deferred.tsv` `skill:` rows, `skill-steps-exempt.tsv` rows, and the SG-04 exempt rows.

---

## 3. Tasks

`Source` reads `feature-003-work-definition -> delivery-004 -> AC-...`.

### task-082: Delivery-004 site search and reconciled edit list [RESEARCH]

- **Depends on:** --.
- **Source:** AC-17, AC-43.
- **Scope:** creates `research/delivery-004-sites.md`, with the same shape and owner classes as before.
  It re-runs these searches:
  - **R1** `aid-describe`, `/aid-describe` and `aid-design` (any form) over `canonical/`,
    `dashboard/home.html`, `tests/`, `site/scripts/`, `scripts/checks/` and `.aid/knowledge/`;
  - **R2** `.aid/design/` under `canonical/skills/` and `canonical/aid/templates/` (ID-03's scope), plus
    every `git add` / `git rm` / `git commit` on it;
  - **R3** `verb: design` rows and the comments naming them;
  - **R4** the "No works found" lines that name `/aid-describe`;
  - **R5** the Q106 map for every file on the edit list, including the site's skill lists and
    `__tests__`;
  - **R6** the rows of the deferred list and of both exempt lists that name the retiring skills;
  - **R7** the statements each retiring `aid-design-*` skill makes about what its seed must settle, which
    are the source of each kind's `shape` (F003 § 4).
- **Acceptance criteria:**
  - [ ] Each search shows its command, and re-running it at the named base reproduces it.
  - [ ] Every hit has exactly one owner among task-083 to task-103 (or resync or history), and no owner
    cell is empty.
  - [ ] R7 gives one quoted source line per kind for all 21 kinds. RESEARCH defaults are overridden as
    before.

### task-083: Draft script `idea-drafts.sh` [IMPLEMENT]

- **Depends on:** task-082.
- **Source:** AC-17 (draft-location clause; KI-004).
- **Scope:** creates `canonical/aid/scripts/works/idea-drafts.sh` (bash), per F003 § 2:
  - the operations `dir`, `path`, `list`, `collect`, `keep`, `release` and `delete`;
  - exits 0, 2, 3, 4 and 5, each checked before anything runs;
  - no `git push`;
  - main-folder resolution the way `worktree-lifecycle.sh` resolves it.
  The unit suite is task-095.
- **Acceptance criteria:**
  - [ ] In a scratch fixture (a main folder plus one worktree), `dir` prints the same path from both.
    `keep` commits only `.aid/design/<name>.md` on the work branch. `delete` of a loose draft makes no
    commit.
  - [ ] `delete README`, `delete a/b`, and `keep` run in the main folder exit 2, 2 and 4, and change
    nothing (`git status --porcelain` and the file list are unchanged).
  - [ ] `grep -c 'git push' canonical/aid/scripts/works/idea-drafts.sh` prints 0, and `bash -n` passes.

### task-084: Writer fields `Idea Draft` and `Side Idea`, and their template keys [IMPLEMENT]

- **Depends on:** task-082.
- **Source:** AC-17, AC-37.
- **Scope:**
  - `writeback-state.sh --pipeline` accepts `"Idea Draft"` (`idea_draft`) and `"Side Idea"`
    (`side_idea`), with the value `--` or `.aid/design/<name>.md`; anything else exits 4.
  - `work-state-template.yml` gains `idea_draft: --` and `side_idea: --` with `[W]` comments, and the
    `sources[].kind` comment gains `draft`.
  - The unit cases are task-096.
- **Suites updated in the same task:** `test-work-state-template.sh` and existing `test-writeback-state.sh`
  assertions.
- **Acceptance criteria:**
  - [ ] On a scratch work, `--field "Idea Draft" --value .aid/design/orders-api.md` and `--value --`
    succeed; `--value .aid/design/../x.md` and `--value notes.md` exit 4.
  - [ ] The template parses through both readers with no warning (SS-08), and `test-work-state-template.sh`
    passes in the scratch copy.

### task-085: Kind catalog `kind-catalog.yml` (v1) [IMPLEMENT]

- **Depends on:** task-082.
- **Source:** AC-43.
- **Scope:** creates `canonical/aid/templates/kind-catalog.yml`:
  - `version: 1`;
  - one entry per kind of today's `aid-design-*` (21 kinds), each with `kind`, `about`, `shape` (from
    task-082's R7) and `then`;
  - `then` is `KB update` for roadmap, mvp and backlog, and `Specification` for every other kind;
  - block style, per F003 § 4.
- **Acceptance criteria:**
  - [ ] There are 21 entries, and each has non-empty `kind`, `about` and `shape`, and a `then` of
    `Specification` or `KB update`. This is ID-04's rule ahead of its suite.
  - [ ] It parses with no flow collection; `grep -nE '^[^#]*:[[:space:]]*[[{][^]}]'` finds nothing.

### task-086: Idea-draft shape and the design-folder README [IMPLEMENT]

- **Depends on:** task-082.
- **Source:** AC-17.
- **Scope:** per F003 § 2:
  - `canonical/aid/templates/design-seed.md` gets the nine sections of the draft's shape.
    `## Destination` goes, and so does the open-questions readiness gate.
  - `canonical/aid/templates/design-folder-readme.md` and this repository's `.aid/design/README.md` get
    the one lifecycle text.
- **Acceptance criteria:**
  - [ ] `design-seed.md` holds exactly F003 § 2's headings in order, with no `## Destination` and no
    `## Change Log`.
  - [ ] Both README files hold the lifecycle sentence verbatim (ID-05's rule, presence only).

### task-087: `/aid-brainstorm` rewrite: the skill, START and CONVERSE [IMPLEMENT]

- **Depends on:** task-083, task-084, task-085, task-086.
- **Source:** AC-17, AC-28, AC-37, AC-43.
- **Scope:**
  - `canonical/skills/aid-brainstorm/SKILL.md`, at most 100 lines:
    - the step table of F003 § 3;
    - `skill-steps.md` and `question-protocol.md` cited;
    - the description in Feature 001's shape (F003 § 5);
    - `argument-hint: "[<kind>] <idea>"`.
  - Creates `references/start.md`, `converse.md` and `shaping-moves.md` (each at most 120 lines). They
    cover:
    - START's `list`, offer, `collect`, the new draft and the README on first use;
    - CONVERSE's loop, the Q49 closing question, pausing, and the `aid-architect` worker;
    - the shaping moves condensed from `aid-describe`.
  - The `aid-brainstorm` row of `shortcut-catalog.yml` gets its `intent:` rewritten, and the
    `/aid-brainstorm` line of the `rules.md` guide is rewritten.
  - Its `skill-steps-exempt.tsv` row goes.
- **Acceptance criteria:**
  - [ ] The step table reads START, CONVERSE, CHECK, FINISH, with the advance words of F003 § 3.
    `converse.md` holds the Q49 question verbatim.
  - [ ] `start.md` cites `idea-drafts.sh list` / `path` and `kind-catalog.yml`. No file under the skill
    stages, commits or pushes `.aid/design/`.
  - [ ] The line caps hold. `test-skill-guide.sh` (SG-02 to SG-04) and `test-skill-steps.sh` pass in the
    scratch copy.

### task-088: The draft deletion rule and the gate's two legacy rows [IMPLEMENT]

- **Depends on:** task-083, task-084.
- **Source:** AC-17, AC-37.
- **Scope:**
  - `skill-steps.md` § When approvals happen gains the deletion rule and table: `idea-drafts.sh delete`,
    then clear `idea_draft`; a `draft` source keeps its entry, with `effect` noting the deletion.
  - The legacy block of `work-initiation-gate.md` § 3b gains the two rows of F003 § 6 at its top.
    Flagged: F-1.
  - The new `--check` fixtures are task-096.
- **Suites updated in the same task:** the existing `test-work-initiation-gate.sh` assertions.
- **Acceptance criteria:**
  - [ ] § When approvals happen names `idea_draft` and `idea-drafts.sh` (ID-06's rule).
  - [ ] The two rows sit first inside the legacy markers, and `test-work-initiation-gate.sh` passes live.

### task-089: `/aid-orchestrate` routing rows and the kind hook [IMPLEMENT]

- **Depends on:** task-083, task-085.
- **Source:** AC-7, AC-43.
- **Scope:**
  - `size-and-route.md` gains the two phase-table rows of F003 § 5.
  - `check-intent.md`'s kind hook matches design requests against `kind-catalog.yml` `about:`, and treats
    a draft that `idea-drafts.sh list` shows as evidence of an idea under way.
  - The line caps hold.
- **Acceptance criteria:**
  - [ ] Both rows are present verbatim, and `check-intent.md` cites `kind-catalog.yml` and
    `idea-drafts.sh list`.
  - [ ] Each reference is at most 120 lines, and the site `npm test` passes.

### task-090: `/aid-brainstorm` rewrite: CHECK, FINISH, parking and side ideas [IMPLEMENT]

- **Depends on:** task-087.
- **Source:** AC-17, AC-37, AC-38.
- **Scope:** creates `references/check.md`, `reviewer-brief.md` (with `### What to report`, and the four
  findings of F003 § 3) and `finish.md`. `finish.md` covers:
  - the draft shown in chunks;
  - the `full` approval;
  - the next-step question with the kind's `then` recommended;
  - `PASS` to `aid-specify` or `aid-kb-update`;
  - the keep question;
  - parking, with the set-aside question;
  - side ideas: back into the work, keep it in a work, or keep it as a draft;
  - `HALT` or `PASS` back.
- **Acceptance criteria:**
  - [ ] `finish.md` names `aid-specify`, and FINISH advances by `PASS` (ID-07's rule). The keep question
    recommends no, and side ideas never touch `idea_draft`.
  - [ ] `reviewer-brief.md` has `### What to report` (SS-13), and each file is at most 120 lines.

### task-091: Re-point the skills that name `/aid-describe` or `/aid-design` [IMPLEMENT]

- **Depends on:** task-087. Boundary lines now name `/aid-brainstorm`.
- **Source:** AC-43.
- **Scope:** per F003 § 6, re-pointed lines:
  - the "No works found" lines of `aid-define`, `aid-specify`, `aid-plan`, `aid-detail`, `aid-execute` and
    `aid-deploy`;
  - `aid-discover` `references/state-generate.md`, `path-config.md` and `state-review.md`;
  - `aid-define` `references/state-done.md`;
  - the reviewer briefs of `aid-discover`, `aid-plan` and `aid-specify`;
  - `aid-monitor` `references/state-route.md`;
  - the boundary lines of `aid-prototype`, `aid-prototype-ui`, `aid-document` and `aid-create-document`,
    and `aid-research`'s;
  - the `.aid/design/<kind>.md` reads of `aid-create-document` and `aid-update-document`.
- **Acceptance criteria:**
  - [ ] Over these skills, `git grep -nE 'aid-describe|aid-design'` finds nothing, and neither document
    skill reads `.aid/design/`.
  - [ ] Their suites pass where the test step puts them, and the site `npm test` passes.

### task-092: Re-point the templates and scripts; trim `design-lifecycle.md` [IMPLEMENT]

- **Depends on:** task-087, task-088. task-088 edits the gate file first.
- **Source:** AC-43.
- **Scope:** per F003 § 6:
  - the descriptive mentions in `connectors/consumption-protocol.md`, `requirements/requirements-template.md`,
    `reviewer-ledger-schema.md`, the `> **Source:**` lines of the four `knowledge-base/` templates,
    `shortcut-engine.md`, `shortcut-scaffolding/analyze-report.md`, `work-initiation-gate.md` (outside the
    legacy block) and `work-state-template.yml`;
  - `canonical/aid/scripts/kb/recon-classify.sh` and `scripts/checks/review-path-audit.sh`;
  - `shortcut-engine.md` § Step 2: Read context drops its `.aid/design/<kind>.md` read;
  - `design-lifecycle.md` keeps only the rules for the KB-writing create/update skills (F003 § 5).
- **Suites updated in the same task:** `test-connector-consumption-linkage.sh`,
  `test-ticket-retirement-structural.sh`, `test-work-state-template.sh`, `test-shortcut-engine-contract.sh`,
  and whatever task-082 assigns.
- **Acceptance criteria:**
  - [ ] `git grep -nE 'aid-describe|aid-design'` over these files finds only lines inside the gate's legacy
    markers.
  - [ ] `design-lifecycle.md` has no `design` stage, no seed naming by kind and no `/aid-brainstorm` case.
    The suites pass.

### task-093: `/aid-describe` retired [IMPLEMENT]

- **Depends on:** task-088, task-090, task-091, task-092. All its referrers are re-pointed first, and its
  parts have moved.
- **Source:** AC-43 (and AC-24 via task-097).
- **Scope:**
  - Deletes `canonical/skills/aid-describe/` and its guide line.
  - `dashboard/home.html`'s empty state becomes "tell your AI tool what you want to build", with
    `test_index_html.py`.
  - Deletes `tests/canonical/test-describe-full-only.sh`, with the accepted-removal rows.
  - Updates the suites that name it: `test-work-initiation-gate.sh`, `test-path-fixtures.sh`,
    `test-pipeline-status-walkthrough.sh`, `test-cutover-no-dangling.sh` and
    `test-deploy-monitor-repurpose.sh`.
  - Updates the site skill lists and `__tests__`, then regenerates the site.
  - Its rows in `deferred.tsv`, the exempt lists and SG-04 go. The counts are re-synced.
  - The dashboard's `SHORTCUT_KIND_MAP` and `_FULL_PATH_INITIATOR` stay (F003 § 6).
- **Acceptance criteria:**
  - [ ] `test -e canonical/skills/aid-describe` fails, and outside the legacy block nothing under
    `canonical/` or `dashboard/home.html` names it (ID-02's rule).
  - [ ] DT-01, SG-04 and the shared exempt list pass, and `test-doc-counts.sh` passes live.
  - [ ] `test_index_html.py` and the site `npm test` pass.

### task-094: `/aid-design` and every `/aid-design-<kind>` retired [IMPLEMENT]

- **Depends on:** task-089 (design requests now route to `/aid-brainstorm`), task-093 (same lists and
  site files).
- **Source:** AC-43.
- **Scope:**
  - Deletes `canonical/skills/aid-design/` and the 21 `aid-design-*` folders.
  - Removes every `verb: design` row of `shortcut-catalog.yml`, with its comments.
  - Removes their guide lines.
  - Updates `test-deploy-monitor-repurpose.sh` (catalog totals), `test-prototype-family-scaffold.sh` and
    the site lists and tests, then regenerates the site.
  - The rows in `deferred.tsv` (`skill:aid-design`, `skill:aid-design-*`), the exempt lists and SG-04 go.
  - The counts are re-synced.
- **Acceptance criteria:**
  - [ ] No `aid-design*` folder exists, and `grep -c 'verb: design' canonical/aid/templates/shortcut-catalog.yml`
    prints 0 (ID-01's rule).
  - [ ] `build-shortcut-skills.py --check` exits 0. SG-02, DT-01 and `test-doc-counts.sh` pass.

### task-095: Unit cases: `test-idea-drafts.sh` [TEST]

- **Depends on:** task-083.
- **Source:** AC-17; KI-004.
- **Scope:** creates `tests/canonical/test-idea-drafts.sh`, with every case of F003 § 7 (Unit tests), run
  on throwaway git fixtures with a main folder and a worktree.
- **Acceptance criteria:**
  - [ ] It passes. Each case of F003 § 7 has a named assertion, including "another staged file is never
    committed" and "nothing changes the main folder's branch".
  - [ ] Each exit code (2, 3, 4, 5) has a case that also proves nothing changed. The suite is
    deterministic and cleans up.

### task-096: Unit cases: the writer fields and the new legacy-row fixtures [TEST]

- **Depends on:** task-084, task-088.
- **Source:** AC-17, AC-37.
- **Scope:**
  - `test-writeback-state.sh`: `"Idea Draft"` and `"Side Idea"` accept `--` and a valid identity, refuse
    anything else with exit 4, and the file still parses.
  - `test-work-initiation-gate.sh`: one `--check` fixture per new legacy row.
- **Acceptance criteria:**
  - [ ] Both suites pass, with the named cases. Each case fails when its code or row is broken in a scratch
    copy.

### task-097: KB decisions, backlog, roadmap, tech debt and schemas for idea drafts [DOCUMENT]

- **Depends on:** task-088, task-094.
- **Source:** AC-17, AC-24, AC-43.
- **Scope:** edits these documents under `.aid/knowledge/` (F003 § 6), with no work id:
  - `decisions.md`: the new decision, which supersedes D27 and D24 and amends D28, all three marked;
  - `backlog.md` § Next Release: the three old -> new rows;
  - `roadmap.md` § MVP;
  - `tech-debt.md`: SY-4 resolved (G-03);
  - `artifact-schemas.md`: `idea_draft`, `side_idea` and `kind-catalog.yml`.
- **Acceptance criteria:**
  - [ ] The three backlog rows carry F003 § 6's New text. D24, D27 and D28 are marked in the summary table
    and in their sections.
  - [ ] SY-4 leaves no trace. No work id, and the lints pass.

### task-098: KB architecture and navigation documents for idea drafts [DOCUMENT]

- **Depends on:** task-089, task-094.
- **Source:** AC-17, AC-43.
- **Scope:**
  - `architecture.md`: the design family row;
  - `capability-inventory.md`;
  - `module-map.md`;
  - `pipeline-contracts.md`: the `design` verb rows;
  - `domain-glossary.md`: idea draft; the design family and describe go;
  - `project-structure.md`: `.aid/design/`.
- **Acceptance criteria:**
  - [ ] Over the six documents, `git grep -nE 'aid-describe|aid-design'` finds nothing outside a marked
    superseded decision, and the glossary defines "idea draft".
  - [ ] No work id, and the lints pass.

### task-099: `test-idea-shaping.sh` (ID-01 to ID-07) and the exempt codes [TEST]

- **Depends on:** task-085, task-086, task-090, task-092, task-094.
- **Source:** AC-17, AC-43.
- **Scope:**
  - Creates `tests/canonical/test-idea-shaping.sh` with ID-01 to ID-07, `# COVERS:` lines and a group
    filter.
  - `skill-steps-exempt.tsv` gains `ID-02` / `ID-03` in `checks` for the KB-writing create/update skills
    and `design-lifecycle.md`, with owner Feature 004.
- **Acceptance criteria:**
  - [ ] The suite passes. Each group fails its own mutation in a scratch copy: a `canonical/skills/aid-design-x/`
    folder; an `aid-describe` line; a `git add .aid/design` in a skill; an empty `shape`; a missing seed
    heading; no `idea_draft` in `skill-steps.md`; a step table without CHECK.
  - [ ] `test-skill-steps.sh` still passes with the new codes.

### task-100: Samples `003-01` to `003-05` (run at this gate) [TEST]

- **Depends on:** task-089, task-090, task-094.
- **Source:** AC-17, AC-28, AC-37, AC-43.
- **Scope:** creates `tests/conversation/samples/feature-003/003-01` to `003-05`, with `skills:
  aid-brainstorm`, their fixtures, and the checks of F003 § 7. `003-03`'s ticket is a fixture file
  (Q134 D9). Each gets one smoke run in a scratch copy (Q134 D8).
- **Acceptance criteria:**
  - [ ] There are five files whose `covers` matches F003 § 7, and no answer sheet names a skill.
  - [ ] `003-04` checks the work is `Canceled` and no commit was made. `003-05` checks one commit touching
    only the draft, and nothing pushed.
  - [ ] Each has had one smoke run, with its result reported.

### task-101: Samples `003-06` to `003-11` and the deferred list [TEST]

- **Depends on:** task-100. Both edit the deferred list through the samples' existence.
- **Source:** AC-17, AC-35, AC-37, AC-38, AC-43.
- **Scope:**
  - Creates the six deferred samples of F003 § 7.
  - `deferred.tsv` gains them (`003-11` with its two Feature 004 needs), loses `skill:aid-brainstorm`, and
    re-dates `002-12` (Feature 005 only) and `002-08` (Features 005, 006, 007).
- **Acceptance criteria:**
  - [ ] DT-01 passes, and every Feature 003 sample except `003-01` to `003-05` has a row.
  - [ ] No `skill:aid-brainstorm` row remains, and SS-09 still passes.

### task-102: The two new suites in the CI lane [CONFIGURE]

- **Depends on:** task-095, task-099.
- **Source:** AC-25.
- **Scope:** the `installer-tests.yml` `SUITES` list gains `test-idea-shaping` and `test-idea-drafts`.
- **Acceptance criteria:**
  - [ ] Each name appears once, and the lane loop over `SUITES` exits 0 in the scratch copy.
  - [ ] The workflow-reading suites pass, and no secret is added.

### task-103: KB test landscape for the idea suites, and the regenerated index [DOCUMENT]

- **Depends on:** task-097, task-098, task-101, task-102.
- **Source:** AC-17, AC-25.
- **Scope:** `test-landscape.md` gains the two new suites and `test-describe-full-only.sh` goes. Then
  `INDEX.md` is regenerated.
- **Acceptance criteria:**
  - [ ] `test-landscape.md` names `test-idea-shaping.sh` and `test-idea-drafts.sh`, and
    `grep -c test-describe-full-only .aid/knowledge/test-landscape.md` prints 0.
  - [ ] `INDEX.md` is regenerated; no work id, and the lints pass.

---

## 4. Coverage, and steps that are not tasks

| Stanza item / gate criterion | Task(s) |
|---|---|
| `aid-brainstorm` rewritten (START, CONVERSE, CHECK, FINISH; parking, side ideas) | 087, 090 |
| `idea-drafts.sh`; the deletion rule; the writer fields | 083; 088; 084 |
| `kind-catalog.yml`; retirements; `verb: design` rows | 085; 093, 094; 094 |
| `design-seed.md`, the README, `design-lifecycle.md`; legacy rows; routing rows; dashboard empty state | 086; 092; 088; 089; 093 |
| ID-01 to ID-07; `test-idea-drafts.sh`; `SUITES` | 099; 095; 102 |
| Writer accepts the fields, exits 4 otherwise; a legacy-row `--check` fixture each | 096 |
| Samples `003-01` to `003-05`; deferred rows | 100; 101 |
| G0: AC-24 rows; KB; `INDEX.md` | 097; 097, 098, 103 |

**Steps that are not tasks:**
1. `--delivery-id 004 --lifecycle Executing`.
2. The tasks.
3. Verification.
4. The resync (`delivery-004: resync`). `aid update` removes the 23 retired skills through the manifest.
5. The gate, in a new session:
   - the stanza's criteria;
   - `003-01` to `003-05` at 3 of 3, and `001-08` again (`run.py --feature 001 --sample 001-08-bare-idea`);
   - G0 with the baselines;
   - the tracking proof for task-082 to task-103.

---

## 5. Execution graph

| Task | Depends On |
|------|-----------|
| task-082 | -- |
| task-083, task-084, task-085, task-086 | task-082 |
| task-087 | task-083, task-084, task-085, task-086 |
| task-088 | task-083, task-084 |
| task-089 | task-083, task-085 |
| task-090 | task-087 |
| task-091 | task-087 |
| task-092 | task-087, task-088 |
| task-093 | task-088, task-090, task-091, task-092 |
| task-094 | task-089, task-093 |
| task-095 | task-083 |
| task-096 | task-084, task-088 |
| task-097 | task-088, task-094 |
| task-098 | task-089, task-094 |
| task-099 | task-085, task-086, task-090, task-092, task-094 |
| task-100 | task-089, task-090, task-094 |
| task-101 | task-100 |
| task-102 | task-095, task-099 |
| task-103 | task-097, task-098, task-101, task-102 |

`derive-waves.sh --from-tasks` derives the following from the written task files:

```text
wave 1: task-082
wave 2: task-083, task-084, task-085, task-086
wave 3: task-087, task-088, task-089, task-095
wave 4: task-090, task-091, task-092, task-096
wave 5: task-093
wave 6: task-094
wave 7: task-097, task-098, task-099, task-100
wave 8: task-101, task-102
wave 9: task-103
```

Step 5 writes the table under `### delivery-004 Execution Graph`, one task per row.

---

## 6. Settled by recommendation (Q136)

| # | Point | Settled as | Basis |
|---|---|---|---|
| S1 | The `aid-brainstorm` rewrite is six references plus `SKILL.md`, too much for one review. | Two tasks: the skill with START and CONVERSE (087), then CHECK, FINISH, parking and side ideas (090). | One session and one review per task. |
| S2 | Retire first, or re-point first? | Re-point first (091, 092), then delete (093, 094), so nothing ever names a missing skill. | SR-01 / G-09; same-task rule. |
| S3 | Where do the deferred-list, exempt-list and SG-04 rows of the retired skills go? | In the same retirement task. | DT-01, the shared exempt list and SG-04 each fail on a missing folder. |
| S4 | `aid-brainstorm` has no SG-04 exempt row to drop. | No action; its description is rewritten in task-087 anyway. | Q134 D4. |
| S5 | User documentation edits. | Only the counted numbers `test-doc-counts.sh` asserts, re-synced in task-093 and task-094. | F003 § 6, "User documentation"; Q134 D5. |
| S6 | Unit cases and samples come in TEST tasks; samples `003-01` to `003-05` get one smoke run; `test-landscape.md` comes last. | As in delivery-002 and delivery-003. | Q134 D2 and D8; Q135 R1 and R3. |
| S7 | `003-03`'s "ticket exported as a file". | A fixture file. | F003 § 7 states it; Q134 D9. |

---

## 7. Flagged for the maintainer

> **Decided (Q137): option a, narrow the row.** REQUIREMENTS.md F003 § 6 now carries the narrowed row, and task-088
> and task-096 follow it, including a negative case: an `aid-describe` work at `phase: Plan` does not
> route to `/aid-specify`.

**F-1. The `aid-describe` legacy row conflicts with Feature 006's migration order.** This would change an
approved spec, so it is not settled.

- **The conflict.**
  - F003 § 6 puts the row "`pipeline.initiator` is `aid-describe`, or `phase: Describe` -> `/aid-specify`" at
    the **top** of the gate's legacy block, "so they win over the phase rows".
  - F006's migration step applies the same initiator rows only to works at `phase: Describe` (its rule 4),
    after rule 3, under which "a phase other than the default decides".
  - F005 (§ Migration, Existing works) says "Feature 006's migration uses the same rows".
  - Read as written, from delivery-004 until delivery-008 removes the block, recovery would propose
    `/aid-specify` for **every** old full-path work started by `aid-describe`, whatever its phase. That
    includes a work in Plan or Execute.
- **The impact on this work.** None in practice. Its `pipeline.initiator` is `aid-describe`, but nothing
  resumes it by recovery before delivery-009, whose switch runs an explicit
  `--repair --skill aid-execute` (PLAN § Toolchain and Branching, switch table). Delivery-008's migration
  follows F006's order, so `phase: Execute` -> `/aid-execute`, as the plan expects.
- **The impact on the product.** The block exists only between delivery-004 and delivery-008, and nothing
  is released in between. The risk is a wrong recovery proposal for a user's work only if a build were
  released mid-way.
- **Recommendation.** Narrow the row to "`pipeline.initiator` is `aid-describe` **and** `phase` is
  `Describe` (or `phase: Describe` alone)". That matches F006's rule 4. It is a one-line edit to F003 § 6
  and to task-088's scope; nothing else changes.
- **Until decided,** task-088 follows F003 § 6 as written.
