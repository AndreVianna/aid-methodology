# Detail proposal -- delivery-014: Final documentation pass and release readiness

This is `aid-detail` FIRST-RUN for **delivery-014**, under Q136. Decisions are settled by recommendation, the task
files are written at once, and the light review is the check.

## 1. The tasks at a glance

| Task | Title | Type | Stanza wave | Derived wave | Depends on |
|---|---|---|---|---|---|
| task-353 | Delivery-014 documentation search and reconciled rewrite list | RESEARCH | 1 | 1 | -- |
| task-354 | The pre-release name check: retired-names.txt and test-doc-names.sh | TEST | 2 | 2 | task-353 |
| task-355 | The name check in the CI lane and in the live release checks | CONFIGURE | 2 | 3 | task-354 |
| task-356 | Final pass: docs/aid-methodology.md | DOCUMENT | 2 | 3 | task-353, task-354 |
| task-357 | Final pass: the FAQ, the glossary and the repository structure | DOCUMENT | 2 | 4 | task-356 |
| task-358 | Final pass: install, release and the old -> new table | DOCUMENT | 2 | 5 | task-357 |
| task-359 | Final pass: the site's home page, concepts and getting started | DOCUMENT | 2 | 6 | task-358 |
| task-360 | Final pass: the site's guides and hand-written reference pages | DOCUMENT | 2 | 6 | task-358 |
| task-361 | Final pass: README.md and the examples | DOCUMENT | 2 | 6 | task-358 |
| task-362 | Release readiness before the gate: regeneration, the site build and the flagged checks | TEST | 2 | 7 | task-355, task-356, task-357, task-358, task-359, task-360, task-361 |
| task-363 | KB test landscape for the name check, the regenerated index and the view | DOCUMENT | 2 | 8 | task-355, task-362 |

That is 11 tasks (task-353 to task-363). Stanza wave 3 is the resync, which is no task; the release checks under
`AID_RELEASE_CHECK=1` and the full integration suite are gate checks after it (§ 4).

---

## 2. Inputs, measurements and the rules every task carries

- **Source of truth.** The task files under `deliveries/delivery-014/tasks/` (after delivery-008's migration,
  `tasks/task-NNN/DETAIL.md`, G15). The task blocks in § 3 are rendered from the same data.
- **Numbering** continues from delivery-013's task-352.
- **Inputs read:** the delivery-014 stanza of `PLAN.md`; G0; "Testing before the resync" (FINAL's recorded
  `full_suite.command`, the driver); "Toolchain and Branching" (the resync rule; "After delivery-014, the work reaches
  CI"); `REQUIREMENTS.md` § 11 Feature 009 § 5 (The final documentation pass), § 8 (Migration table, Lists) and § 9
  (DN-01 to DN-03; At the end of the work); Q104; Q135 D2 (where the release checks run).
- **Measured at base `9068ed22`** (task-353 re-measures on the finished tree):
  - `docs/` holds eight pages (3,877 lines; `aid-methodology.md` alone 1,496); `sync-docs.mjs` syncs four of them
    (`aid-methodology.md`, `faq.md`, `repository-structure.md`, `glossary.md`) into the site;
  - `site/src/content/docs/` holds about 25 pages outside `skills/`; `reference/skills.md`, `agents.md`, `settings.md`
    and `kb.md` are generated; the rest are synced or hand-written;
  - `README.md` has 302 lines; `examples/` has three example folders.
- **How this delivery is built: the new `/aid-execute`**, as deliveries 010-013. This is the last delivery, so FINAL
  runs here, through the recorded `full_suite.command` (the driver from delivery-010's gate session).
- **Blocks every task carries:** the same-task rule and the findings bullet (G9); the research task's owner classes,
  G2 table and site-fixture search; the KB-coexistence block in the KB task (363); no IMPLEMENT task, so no G3 block;
  the documentation tasks run `sync:docs`, the generators and the site `npm test` (G1, G5), and never edit a
  generated page by hand.
- **Order is an edge (G4, G12):** the synced pages and their manifest follow every `docs/` edit, so the `docs/` tasks
  form a chain (356 -> 357 -> 358); the old -> new table (358) comes before every page that links to it (359, 360, 361);
  the release pre-check (362) follows every rewrite. The `g12scan.py` hits left are file names the shared pass block
  only names (`gen-skills.mjs`, `gen-reference.mjs`, `test-doc-counts.sh`) and `index.md` / `overview.md` of different
  site folders.

---

## 3. Tasks

`Source` reads `feature-009-one-skill-per-need -> delivery-014 -> AC-...`.

### task-353: Delivery-014 documentation search and reconciled rewrite list [RESEARCH]

- **Stanza wave:** 1. **Depends on:** --.
- **Source:** AC-24, AC-45.
- **Scope:**
  - Create `.aid/works/work-003-full-aid-restructure/research/delivery-014-sites.md`. Touch nothing else.
  - Re-run these searches at this task's base commit, and record the base commit in the file
    (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, The final documentation pass; `##### 9. Testing`, DN-01 to DN-03). `test-doc-names.sh`
    comes with task-354, so the DN rules are run by hand, as the spec states them:
    - **D1** DN-01's rule without the release flag: over `docs/`, `site/src/content/` and `examples/`, and `README.md`,
      every mention of a retired slash name (as `/aid-<name>` or in backticks) and every old phase name (Discover,
      Describe, Define, Specify, Plan, Detail, Execute) written as a phase -- in a `->` or `→` sequence, or followed by
      "phase";
    - **D2** the retired names: every skill folder under `canonical/skills/` at the work's base
      (`git merge-base master HEAD`) that `canonical/skills/` no longer holds, and every family form the old -> new
      table of `.aid/knowledge/backlog.md` § Next Release names; the two lists compared, each difference named;
    - **D3** DN-03's rule without the flag: the identity search, `git grep -lIiE 'building software|software-development lifecycle|AI Integrated Software Development|methodology for software development|kind of digital work' -- . ':!.aid/works' ':!site/src/data' ':!.aid/knowledge/kb.html' ':!.aid/runtime' ':!tests' ':!**/tests/**' ':!**/__tests__/**'`, over `docs/` and `site/src/content/docs/`,
      and every file it finds without "software first, not software only";
    - **D4** each page under `site/src/content/docs/`, classed as generated (`gen-skills.mjs`, `gen-reference.mjs`),
      synced from `docs/` (`sync-docs.mjs`'s manifest) or hand-written;
    - **D5** the counted phrases `test-doc-counts.sh` asserts, with their files;
    - **D6** every link into a page or anchor the pass renames or removes.
  - **Site fixtures (G11, extended).** Also search `site/scripts/__tests__/` and `site/src/lib/__tests__/` for every
    test that reads a real skill's or template's body as a fixture -- by path, or by name through `loadSkillRecord`,
    `buildFlowChart`, `liveChart` or the like (`git grep -nE "'aid-[a-z-]+'|canonical/(skills|aid/templates)/" --
    site/scripts/__tests__ site/src/lib/__tests__`). Each hit on a file this delivery rewrites, moves or deletes goes to
    the task that changes that file, which re-points the test in the same task.
  - Give each hit exactly one owner:
    - a task of delivery-014 (task-354 to task-363; see the task files under
      `.aid/works/work-003-full-aid-restructure/tasks/task-NNN/DETAIL.md`, the layout delivery-008's migration leaves):
      task-356 (`docs/aid-methodology.md`), task-357 (`docs/faq.md`, `glossary.md`, `repository-structure.md`),
      task-358 (`docs/install.md` with the old -> new table, `release.md`, `chat-wake-install.md`,
      `diagram-content-reference.md`), task-359 (the hand-written site pages of the home page, `concepts/` and
      `get-started/`), task-360 (the hand-written site pages of `guides/`, `reference/` and `contact/`), task-361
      (`README.md` and `examples/`);
    - "generated page: regenerated" (no hand edit) and "synced page: follows its `docs/` source";
    - "installed copy (resync)";
    - "history, left as is";
    - "rendered after the resync (gate step)" for hits in `.aid/knowledge/kb.html`, `.aid/knowledge/INDEX.md` and the
      site pages generated from `.aid/settings.yml` (`reference/settings.md`) (G8).
  - In a delta section, list each file assigned to two independent tasks, with the order to edit it.
  - **The owner classes also include "baseline, re-recorded at the gate"** for hits in
    `tests/cost-baseline.tsv` and `tests/coverage-baseline.tsv`. No task edits a baseline (Q134 D11).
  - **Skill owner table (G2).** Build it from a full listing, `ls canonical/skills/*/SKILL.md`, not from
    text searches. It has one row per skill on disk at the base, naming the task of this delivery that owns
    that skill's edits, or "no change needed here" with the reason (for example "generated doorway: changes
    through the builder").
- **Acceptance criteria:**
  - [ ] Each of D1-D6 shows its exact command, and re-running it at the base named in the file reproduces its hits.
  - [ ] Every hit has exactly one owner; the count of rows with an empty owner cell is 0; D2's two lists agree or each difference has its owner.
  - [ ] The skill owner table has exactly one row per `canonical/skills/*/SKILL.md` on disk at the base (the row count equals `ls canonical/skills/*/SKILL.md | wc -l`), and no row is unowned.
  - [ ] RESEARCH defaults are overridden as in task-001; the test step selects nothing (work folder only).

### task-354: The pre-release name check: retired-names.txt and test-doc-names.sh [TEST]

- **Stanza wave:** 2. **Depends on:** task-353.
- **Source:** AC-24, AC-45.
- **Scope:**
  - Create `tests/canonical/retired-names.txt` (REQUIREMENTS.md § 11 Feature 009 `##### 9. Testing`, Pre-release check): every retired slash name,
    one per line, kept equal to the old -> new table of `.aid/knowledge/backlog.md` § Next Release (the findings' D2).
  - Create `tests/canonical/test-doc-names.sh`, a bash harness on `tests/lib/assert.sh` with `# COVERS:` lines and a
    group filter:
    - **DN-01**: with `AID_RELEASE_CHECK=1`, no file under `docs/`, `site/src/content/` or `examples/`, nor `README.md`,
      names a name of `retired-names.txt` as `/aid-<name>` or in backticks, nor an old phase name as a phase (in a `->`
      or `→` sequence, or followed by "phase"); text between `legacy-skill-names` markers is skipped. Without the flag
      it prints the hits and passes;
    - **DN-02**: no name of `retired-names.txt` is a folder under `canonical/skills/`; with the flag, each has a row in
      the old -> new table of `backlog.md` § Next Release;
    - **DN-03**: with the flag, every file the identity search finds carries "software first, not software only", and
      the same search, with its test-folder exclusions, finds "kind of digital work" in no file.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-014-sites.md` assigns to `task-354`.
- **Acceptance criteria:**
  - [ ] Without the flag the suite passes where the test step puts it and prints the hits the findings' D1 and D3 list; with `AID_RELEASE_CHECK=1` it fails on them, naming each file.
  - [ ] Each check fails its own mutation in a scratch copy: `/aid-create-api` outside the markers in `README.md`; `Specify -> Plan` in a `docs/` page; a `canonical/skills/aid-design/` folder; a name with no `backlog.md` row; "kind of digital work" in `docs/faq.md`. Text between the markers is skipped.
  - [ ] It is deterministic, reads files only, and finishes within the 300-second budget.

### task-355: The name check in the CI lane and in the live release checks [CONFIGURE]

- **Stanza wave:** 2. **Depends on:** task-354.
- **Source:** AC-24, AC-45.
- **Scope:**
  - `.github/workflows/installer-tests.yml`: the bash-harness `SUITES` list gains `test-doc-names`.
  - `release.sh`: its live publish mode's release checks (DT-02 and the two exempt-list checks, Q135 D2) gain
    `test-doc-names.sh` with `AID_RELEASE_CHECK=1`; dry-run and stage-only stay as they are. `release.yml`'s `run-all.sh`
    step already sets the flag, so it runs DN there too.
  - Suites to update in this same task: `tests/canonical/test-release.sh` where it asserts the release checks, and the
    workflow-reading suites where they assert the workflow's text.
- **Acceptance criteria:**
  - [ ] `test-doc-names` appears once in `SUITES`; `release.sh`'s live publish checks name `test-doc-names.sh`, and applying the edit twice changes nothing.
  - [ ] `test-release.sh` passes in the scratch copy, the lane loop over `SUITES` exits 0 there, and no secret is added.

### task-356: Final pass: docs/aid-methodology.md [DOCUMENT]

- **Stanza wave:** 2. **Depends on:** task-353, task-354.
- **Source:** AC-45.
- **Scope:**
  - `docs/aid-methodology.md`, then `(cd site && npm run sync:docs)` for its synced page `concepts/methodology.md`.
  - **The final documentation pass** (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, The final documentation pass; AC-45, Q104):
    `aid-tech-writer` rewrites the files below against the finished product -- the phases (Definition,
    Specification, Planning, Building, CI), the skills as `canonical/skills/` holds them, the action skills with their
    kinds typed or said, the KB skills, `/aid-configure` -- and states the identity the same way everywhere: AID is built for software first, not software only -- its pipeline and kind catalog leave room for other areas of work, which no shipped kind covers yet.
    - A retired skill or an old phase name appears only inside the old -> new table (task-358) or as a link to it;
      an old phase name is never written as a phase (in a `->` or `→` sequence, or followed by "phase").
    - The counted phrases `test-doc-counts.sh` asserts take the derived counts.
    - A generated site page (`gen-skills.mjs`, `gen-reference.mjs`) is regenerated, never edited by hand; a page synced
      from `docs/` changes only through `(cd site && npm run sync:docs)`.
- **Acceptance criteria:**
  - [ ] Run without the release flag, `bash tests/canonical/test-doc-names.sh -v` lists no DN-01 or DN-03 hit in the files this task owns; `test-doc-counts.sh` passes live, and the site `npm test` passes after `sync:docs` and regeneration.
  - [ ] Each statement about a skill, a phase or a file matches `canonical/` as the work leaves it (accuracy verified against the current tree).

### task-357: Final pass: the FAQ, the glossary and the repository structure [DOCUMENT]

- **Stanza wave:** 2. **Depends on:** task-356.
- **Source:** AC-45.
- **Scope:**
  - `docs/faq.md`, `docs/glossary.md` and `docs/repository-structure.md`, then `(cd site && npm run sync:docs)` for their
    synced pages.
  - **The final documentation pass** (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, The final documentation pass; AC-45, Q104):
    `aid-tech-writer` rewrites the files below against the finished product -- the phases (Definition,
    Specification, Planning, Building, CI), the skills as `canonical/skills/` holds them, the action skills with their
    kinds typed or said, the KB skills, `/aid-configure` -- and states the identity the same way everywhere: AID is built for software first, not software only -- its pipeline and kind catalog leave room for other areas of work, which no shipped kind covers yet.
    - A retired skill or an old phase name appears only inside the old -> new table (task-358) or as a link to it;
      an old phase name is never written as a phase (in a `->` or `→` sequence, or followed by "phase").
    - The counted phrases `test-doc-counts.sh` asserts take the derived counts.
    - A generated site page (`gen-skills.mjs`, `gen-reference.mjs`) is regenerated, never edited by hand; a page synced
      from `docs/` changes only through `(cd site && npm run sync:docs)`.
- **Acceptance criteria:**
  - [ ] Run without the release flag, `bash tests/canonical/test-doc-names.sh -v` lists no DN-01 or DN-03 hit in the files this task owns; `test-doc-counts.sh` passes live, and the site `npm test` passes after `sync:docs` and regeneration.
  - [ ] Each glossary entry and structure line matches `canonical/` and the KB's `domain-glossary.md` and `project-structure.md` as the work leaves them.

### task-358: Final pass: install, release and the old -> new table [DOCUMENT]

- **Stanza wave:** 2. **Depends on:** task-357.
- **Source:** AC-24, AC-45.
- **Scope:**
  - `docs/install.md`, `docs/release.md`, `docs/chat-wake-install.md` and `docs/diagram-content-reference.md`, then
    `(cd site && npm run sync:docs)`.
  - **The old -> new table** (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`; AC-24): one table, in `docs/install.md`'s upgrade section,
    between `<!-- legacy-skill-names: begin -->` and `<!-- legacy-skill-names: end -->`, with every row of
    `.aid/knowledge/backlog.md` § Next Release; the one place a document names retired skills. The other documents
    link to it.
  - **The final documentation pass** (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, The final documentation pass; AC-45, Q104):
    `aid-tech-writer` rewrites the files below against the finished product -- the phases (Definition,
    Specification, Planning, Building, CI), the skills as `canonical/skills/` holds them, the action skills with their
    kinds typed or said, the KB skills, `/aid-configure` -- and states the identity the same way everywhere: AID is built for software first, not software only -- its pipeline and kind catalog leave room for other areas of work, which no shipped kind covers yet.
    - A retired skill or an old phase name appears only inside the old -> new table (task-358) or as a link to it;
      an old phase name is never written as a phase (in a `->` or `→` sequence, or followed by "phase").
    - The counted phrases `test-doc-counts.sh` asserts take the derived counts.
    - A generated site page (`gen-skills.mjs`, `gen-reference.mjs`) is regenerated, never edited by hand; a page synced
      from `docs/` changes only through `(cd site && npm run sync:docs)`.
- **Acceptance criteria:**
  - [ ] Run without the release flag, `bash tests/canonical/test-doc-names.sh -v` lists no DN-01 or DN-03 hit in the files this task owns; `test-doc-counts.sh` passes live, and the site `npm test` passes after `sync:docs` and regeneration.
  - [ ] `docs/install.md` holds exactly one marked table, and each name of `tests/canonical/retired-names.txt` appears in it.

### task-359: Final pass: the site's home page, concepts and getting started [DOCUMENT]

- **Stanza wave:** 2. **Depends on:** task-358.
- **Source:** AC-45.
- **Scope:**
  - The hand-written pages the findings' D4 classes under `site/src/content/docs/`: `index.mdx`, `concepts/index.md`,
    `concepts/overview.md`, and the `get-started/` pages (`index.md`, `overview.md`, `install.md`, `first-work.mdx`,
    `lite-path.mdx`), linking to the old -> new table rather than repeating it.
  - **The final documentation pass** (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, The final documentation pass; AC-45, Q104):
    `aid-tech-writer` rewrites the files below against the finished product -- the phases (Definition,
    Specification, Planning, Building, CI), the skills as `canonical/skills/` holds them, the action skills with their
    kinds typed or said, the KB skills, `/aid-configure` -- and states the identity the same way everywhere: AID is built for software first, not software only -- its pipeline and kind catalog leave room for other areas of work, which no shipped kind covers yet.
    - A retired skill or an old phase name appears only inside the old -> new table (task-358) or as a link to it;
      an old phase name is never written as a phase (in a `->` or `→` sequence, or followed by "phase").
    - The counted phrases `test-doc-counts.sh` asserts take the derived counts.
    - A generated site page (`gen-skills.mjs`, `gen-reference.mjs`) is regenerated, never edited by hand; a page synced
      from `docs/` changes only through `(cd site && npm run sync:docs)`.
- **Acceptance criteria:**
  - [ ] Run without the release flag, `bash tests/canonical/test-doc-names.sh -v` lists no DN-01 or DN-03 hit in the files this task owns; `test-doc-counts.sh` passes live, and the site `npm test` passes after `sync:docs` and regeneration.
  - [ ] Each walkthrough's steps match the skills and phases as `canonical/` leaves them.

### task-360: Final pass: the site's guides and hand-written reference pages [DOCUMENT]

- **Stanza wave:** 2. **Depends on:** task-358.
- **Source:** AC-45.
- **Scope:**
  - The hand-written pages the findings' D4 classes under `site/src/content/docs/guides/`, `reference/` and `contact/`
    (today `guides/pipeline.mdx`, `installation.mdx`, `dashboard.mdx`, `maintainer.mdx`, `reference/overview.md`,
    `artifacts.md`, `cli.mdx`, `index.md`), linking to the old -> new table rather than repeating it. The generated
    reference pages (`skills.md`, `agents.md`, `settings.md`, and any the findings class as generated) are regenerated.
  - **The final documentation pass** (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, The final documentation pass; AC-45, Q104):
    `aid-tech-writer` rewrites the files below against the finished product -- the phases (Definition,
    Specification, Planning, Building, CI), the skills as `canonical/skills/` holds them, the action skills with their
    kinds typed or said, the KB skills, `/aid-configure` -- and states the identity the same way everywhere: AID is built for software first, not software only -- its pipeline and kind catalog leave room for other areas of work, which no shipped kind covers yet.
    - A retired skill or an old phase name appears only inside the old -> new table (task-358) or as a link to it;
      an old phase name is never written as a phase (in a `->` or `→` sequence, or followed by "phase").
    - The counted phrases `test-doc-counts.sh` asserts take the derived counts.
    - A generated site page (`gen-skills.mjs`, `gen-reference.mjs`) is regenerated, never edited by hand; a page synced
      from `docs/` changes only through `(cd site && npm run sync:docs)`.
- **Acceptance criteria:**
  - [ ] Run without the release flag, `bash tests/canonical/test-doc-names.sh -v` lists no DN-01 or DN-03 hit in the files this task owns; `test-doc-counts.sh` passes live, and the site `npm test` passes after `sync:docs` and regeneration.
  - [ ] Each artifact, setting and command a page names exists in `canonical/` or `bin/aid` as the work leaves them.

### task-361: Final pass: README.md and the examples [DOCUMENT]

- **Stanza wave:** 2. **Depends on:** task-358.
- **Source:** AC-45.
- **Scope:**
  - `README.md` (its skills, phases, counts and identity line) and `examples/` (its `README.md` and the three example
    folders, their samples written in the new shapes: one `REQUIREMENTS.md`, the generated `PLAN.md`, the single work
    `STATE.yml`), linking to the old -> new table.
  - **The final documentation pass** (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, The final documentation pass; AC-45, Q104):
    `aid-tech-writer` rewrites the files below against the finished product -- the phases (Definition,
    Specification, Planning, Building, CI), the skills as `canonical/skills/` holds them, the action skills with their
    kinds typed or said, the KB skills, `/aid-configure` -- and states the identity the same way everywhere: AID is built for software first, not software only -- its pipeline and kind catalog leave room for other areas of work, which no shipped kind covers yet.
    - A retired skill or an old phase name appears only inside the old -> new table (task-358) or as a link to it;
      an old phase name is never written as a phase (in a `->` or `→` sequence, or followed by "phase").
    - The counted phrases `test-doc-counts.sh` asserts take the derived counts.
    - A generated site page (`gen-skills.mjs`, `gen-reference.mjs`) is regenerated, never edited by hand; a page synced
      from `docs/` changes only through `(cd site && npm run sync:docs)`.
- **Acceptance criteria:**
  - [ ] Run without the release flag, `bash tests/canonical/test-doc-names.sh -v` lists no DN-01 or DN-03 hit in the files this task owns; `test-doc-counts.sh` passes live, and the site `npm test` passes after `sync:docs` and regeneration.
  - [ ] Each example file matches the template it shows (`requirements-template.md`, `plan-template.md`, `work-state-template.yml`) as the work leaves it.

### task-362: Release readiness before the gate: regeneration, the site build and the flagged checks [TEST]

- **Stanza wave:** 2. **Depends on:** task-355, task-356, task-357, task-358, task-359, task-360, task-361.
- **Source:** AC-31, AC-45.
- **Scope:**
  - Run, and record each result in the task's report (REQUIREMENTS.md § 11 Feature 009 `##### 9. Testing`, At the end of the work; PLAN.md
    delivery-014 Gate Criteria):
    - `(cd site && npm run sync:docs && npm run gen:reference && npm run gen:skills)` leaves `git status --porcelain`
      empty, and `(cd site && npm run build)` succeeds;
    - with `AID_RELEASE_CHECK=1`: `test-doc-names.sh` (DN-01, DN-02, DN-03), SG-04 of `test-skill-guide.sh` and the
      shared exempt list's check pass; DT-02 of `test-deferred-tests.sh` reports exactly the rows of `008-15`,
      `009-11` and `009-12`, which wait for the integration run at the gate, and no other.
  - Each suite runs where the test step puts it. A failure is fixed by the task that owns the file (a correction through
    `/aid-plan` REVISE), not here.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-014-sites.md` assigns to `task-362`.
- **Acceptance criteria:**
  - [ ] Each listed check has its result recorded; the regeneration leaves no diff and the site build succeeds.
  - [ ] With the flag, DN-01 to DN-03, SG-04 and the shared exempt list's check pass, and DT-02 lists only the three integration-run rows.

### task-363: KB test landscape for the name check, the regenerated index and the view [DOCUMENT]

- **Stanza wave:** 2. **Depends on:** task-355, task-362.
- **Source:** AC-45.
- **Scope:**
  - `.aid/knowledge/test-landscape.md`: `test-doc-names.sh` and `retired-names.txt`, its lane and its place in the live
    release checks; the full integration run before release (every sample 3 of 3, `008-15`, `009-11`, `009-12`).
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
    1. **The run** builds the tasks and DELIVERY, then FINAL -- the whole suite through the recorded
       `full_suite.command` (the driver, PLAN.md "Testing before the resync") -- then MILESTONE's collect and
       corrections. The approval question (delivery-014 and the whole build) is written `Pending` with `--ask`, and the
       run pauses there; the main conversation ends the session.
    2. **Resync session:** the resync (`delivery-014: resync`), committed alone. Then the session ends.
    3. **Gate session, before the gate (G8):** the installed `derive-waves.sh --plan --check` on this work, with
       `--plan` when stale; `(cd site && npm run gen:reference)` and the site `npm test`, committing any regenerated
       page; the KB is not changed by this resync.
    4. **The gate:**
       - the full integration suite: every sample under `tests/conversation/samples/` 3 of 3, including `008-15` (live
         GitHub and GitLab) and `009-11` and `009-12` (a live tracker);
       - when they pass, their three rows leave `tests/conversation/deferred.tsv`, committed alone (a test-list change,
         not resync-relevant);
       - then, with `AID_RELEASE_CHECK=1`, DN-01 to DN-03, DT-02 and both exempt-list checks, with all three lists empty;
         `gen-skills.mjs` with no diff and the Astro build; G0 on the head, G0's lane item carried by the milestone push.
       Then `/aid-execute` resumes and asks the open approval first; a yes is recorded with `--answer --commit <head>`,
       the push question follows, and the work goes to CI through `/aid-monitor-pipeline`, which marks the pull request
       ready.
- **Acceptance criteria:**
  - [ ] `test-landscape.md` names `test-doc-names.sh`, `retired-names.txt` and the integration run.
  - [ ] `INDEX.md` is regenerated and `render-kb-view.sh --check` exits 0; no work id, and the lints pass.

---

## 4. Coverage, and steps that are not tasks

| Stanza item / gate criterion | Task(s) |
|---|---|
| `aid-tech-writer` rewrites `docs/`, `site/src/content/docs/`, `README.md`, `examples/`; the old -> new table between markers; generated pages regenerated | 356-361 |
| `test-doc-names.sh` (DN-01 to DN-03) and `retired-names.txt`; in the lane and the live release checks | 354, 355 |
| `gen-skills.mjs` with no diff after the pass; the Astro build | 362 (before the gate), and at the gate |
| DT-02 and both exempt-list release checks with the lists empty | 362 (all but the three integration rows); the gate (after the integration run) |
| The full integration suite (every sample 3 of 3, `008-15`, `009-11`, `009-12`) | the gate (task-363's block) |
| G0: KB documents; `INDEX.md`; `kb.html` | 363 |

**Steps that are not tasks** (task-363's "Gate-session steps" block): the run with FINAL through `full_suite.command`
and the approval pause; the resync; the gate session (`derive-waves.sh --plan --check`, `gen:reference` and the site
`npm test`; the integration suite; the three `deferred.tsv` rows removed once it passes, committed alone; the release
checks with the flag; G0); then the approval, the push and CI through `/aid-monitor-pipeline`.

---

## 5. Execution graph

```text
wave 1: task-353
wave 2: task-354
wave 3: task-355, task-356
wave 4: task-357
wave 5: task-358
wave 6: task-359, task-360, task-361
wave 7: task-362
wave 8: task-363
```

Step 5 writes the table under `### delivery-014 Execution Graph`, one task per row (waiting for the go-ahead).

---

## 6. Settled by recommendation (Q136)

| # | Point | Settled as | Basis |
|---|---|---|---|
| S1 | The protocol note and the test step. | As deliveries 010-013. | Settled by recommendation (Q136). |
| S2 | How the pass is cut. | Six DOCUMENT tasks by file set: `aid-methodology.md`; the three other synced `docs/` pages; the remaining `docs/` pages with the table; the site's home, concepts and getting-started pages; its guides and hand-written reference pages; `README.md` and `examples/`. | One session per task; the measured sizes. |
| S3 | Where the old -> new table lives. | One table in `docs/install.md`'s upgrade section, between the `legacy-skill-names` markers; every other document links to it. | F009 § 5 ("the one place a document must name retired skills"); upgrading is installation's subject. |
| S4 | `retired-names.txt`'s content. | Every skill folder of the work's base that no longer exists, plus the table's family forms, checked against `backlog.md` § Next Release (D2). | F009 § 9 ("kept equal to the old -> new table"); DN-02. |
| S5 | Where DN runs with the flag. | `release.yml`'s `run-all.sh` step (already flagged) and `release.sh`'s live publish checks (355), beside DT-02 and the exempt-list checks. | Q135 D2; F009 § 9 ("the pre-release check"). |
| S6 | The three integration-run rows of `deferred.tsv`. | They wait until the gate's integration run passes, then leave in one commit of their own in the gate session (a test-list change, not resync-relevant); then DT-02 runs with the flag. Task-362 checks that they are the only rows left. | PLAN delivery-014 wave 3 (the release checks and the integration suite are gate checks); the integration suite reads the staged bundle, so it runs after the resync. |
| S7 | A pre-gate run of the release checks. | A TEST task (362) runs the regeneration, the site build and the flagged checks before the resync, so the gate finds no pass failure for the first time. | Settled by recommendation (Q136). |
| S8 | KB `sources:` citations and retired skills' site pages (delivery-012 light review rows 1 and 8). | G17: every task that deletes, moves or renames a file fixes the KB `sources:` entries that cite it in the same task (AD14), with a criterion; the DOCUMENT tasks keep the prose. G18: every task that retires or renames a skill `git rm`s its generated page and flow before regenerating, with a criterion. The research task searches `.aid/knowledge/` `sources:` too. | G17, G18 (general rules). |
---

## 7. Flagged for the maintainer

- G16 (the research task's output) stays open; task-353 is written in the form of tasks 254, 288, 311 and 338 until it
  is decided.
