# Detail proposal -- delivery-012: One obvious skill for each need (Feature 009b)

This is `aid-detail` FIRST-RUN for **delivery-012**, under Q136. Decisions are settled by recommendation, the task
files are written at once, and the light review is the check.

## 1. The tasks at a glance

| Task | Title | Type | Stanza wave | Derived wave | Depends on |
|---|---|---|---|---|---|
| task-311 | Delivery-012 site search and reconciled edit list | RESEARCH | 1 | 1 | -- |
| task-312 | The tracker procedures: connectors/ticket-create.md and ticket-update.md | IMPLEMENT | 2 | 2 | task-311 |
| task-313 | The TICKET step and the ticket kind of /aid-create and /aid-update | IMPLEMENT | 2 | 3 | task-312 |
| task-314 | Free-form text after /aid-deploy and /aid-monitor is a plain request | IMPLEMENT | 2 | 2 | task-311 |
| task-315 | No impediment file: the per-row choice in aid-research, aid-review and aid-report | IMPLEMENT | 2 | 2 | task-311 |
| task-316 | Site generator: the skill list from canonical/skills/ | IMPLEMENT | 2 | 2 | task-311 |
| task-317 | Site generator: the flow graph without doorways, engine or siblings | IMPLEMENT | 2 | 3 | task-316 |
| task-318 | The generated wrapper skills retired | IMPLEMENT | 3 | 4 | task-314, task-316, task-317 |
| task-319 | The ticket skills retired, and the ticket seams re-pointed | IMPLEMENT | 3 | 5 | task-313, task-318 |
| task-320 | The document, test and prototype wrappers retired, and the guide's <kind> lines gone | IMPLEMENT | 3 | 6 | task-319 |
| task-321 | The shortcut engine retired, and the shared exempt list empty | IMPLEMENT | 3 | 7 | task-313, task-314, task-316, task-317, task-320 |
| task-322 | The shortcut scaffolding retired | IMPLEMENT | 3 | 8 | task-321 |
| task-323 | The impediment template retired | IMPLEMENT | 3 | 9 | task-315, task-322 |
| task-324 | KB type registry: the generated-skill type retired | DOCUMENT | 3 | 7 | task-320 |
| task-325 | The doorway builder retired, and generate-profile counting from the folders | IMPLEMENT | 3 | 7 | task-320 |
| task-326 | The shortcut catalog retired, with its counting suites | IMPLEMENT | 3 | 9 | task-321, task-322, task-324, task-325 |
| task-327 | Format 6: the doorway rows, inside legacy-skill-names markers | IMPLEMENT | 4 | 10 | task-326 |
| task-328 | Dashboard: the legacy maps inside markers, and no retired name outside them | IMPLEMENT | 4 | 10 | task-326 |
| task-329 | Re-pointing: every kept file that names a retired skill, the engine or its files | IMPLEMENT | 4 | 10 | task-319, task-323, task-325, task-326 |
| task-330 | Migration cases: old doorway works | TEST | 5 | 11 | task-327 |
| task-331 | Dashboard: parity of the two legacy maps inside their markers | TEST | 5 | 11 | task-328 |
| task-332 | test-actions.sh group B | TEST | 5 | 11 | task-313, task-314, task-320, task-323, task-326, task-327, task-328, task-329 |
| task-333 | Samples 009-06, 009-08, 009-09 and 009-10 (plain words, run at this gate) | TEST | 5 | 11 | task-320, task-329 |
| task-334 | Samples 009-11, 009-12, 009-14 and 009-16, the plain runs, and the deferred list | TEST | 5 | 12 | task-313, task-315, task-327, task-333 |
| task-335 | KB decisions, release notes, quality gates, roadmap and tech debt for one skill per need | DOCUMENT | 5 | 11 | task-326, task-329 |
| task-336 | KB architecture, contracts, structure, schemas and glossary without the engine | DOCUMENT | 5 | 12 | task-319, task-326, task-329, task-335 |
| task-337 | KB test landscape for one skill per need, the regenerated index and the view | DOCUMENT | 5 | 13 | task-324, task-330, task-331, task-332, task-334, task-335, task-336 |

That is 27 tasks (task-311 to task-337). The resync follows the run's pause at the delivery-012 MILESTONE approval
(§ 4).

---

## 2. Inputs, measurements and the rules every task carries

- **Source of truth.** The task files under `deliveries/delivery-012/tasks/` are the source of truth (after
  delivery-008's migration, `tasks/task-NNN/DETAIL.md`, G15). The task blocks in § 3 are rendered from the same data.
- **Numbering** continues from delivery-011's task-310.
- **Inputs read:** the delivery-012 stanza of `PLAN.md`; G0; "Testing before the resync"; "Toolchain and Branching";
  `REQUIREMENTS.md` § 11 Feature 009 in full (§ 8 Migration's suite list check by check); `STATE.yml` `qa` Q104,
  Q111-Q137; the delivery-011 task files (what part (a) leaves).
- **Measured at base `9068ed22`** (task-311 re-measures on the tree deliveries 001-011 leave):
  - 46 wrapper folders remain for this delivery after deliveries 004, 006 and 011: 30 generated doorways (13
    `aid-create-<k>`, 13 `aid-update-<k>`, `aid-remove`, `aid-deprecate`, `aid-migrate`, `aid-experiment`) and 16
    hand-authored (`aid-create-ticket`, `aid-update-ticket`, `aid-create-document`, `aid-update-document`,
    `aid-create-diagram`, 7 `aid-document-*`, 3 `aid-test-*`, `aid-prototype-ui`);
  - the site reads the catalog and the engine in `site/scripts/skills/` (`catalog.mjs`; `groups.mjs` stops on a skill
    neither curated nor a catalog row), `gen-reference.mjs` (the engine narrative page) and `lib/flow-graph/`
    (`classify.mjs`'s D4 probe, the engine and sibling extractors);
  - `scripts/checks/g07-selector-partition.sh` (run by `test-criterion-oracles.sh`) evaluates the registry's
    `name-in canonical/aid/templates/shortcut-catalog.yml` selector, so the registry changes before the catalog goes;
  - copy-reading suites among those this delivery changes (their text matches `P`): `test-deploy-monitor-repurpose.sh`,
    `test-downstream-worktree-entry.sh`, `test-shortcut-builder-invariants.sh`, `test-catalog-dirs-parity.sh`,
    `test-shortcut-engine-contract.sh`, `test-ticket-retirement-structural.sh`, `test-artifact-discipline.sh`,
    `test-connector-skills-structural.sh`, `test-aid-cli-parity.sh`, `test-dogfood-byte-identity.sh`; live:
    `test-doc-counts.sh`, `test-work-initiation-gate.sh`, `test-state-review-surface.sh`,
    `test-connector-consumption-linkage.sh`, `test-ticket-skills-structural.sh`. Suites not yet on disk are named
    "where the test step puts it" (G10).
- **How this delivery is built: the new `/aid-execute`**, as deliveries 010 and 011.
- **Blocks every task carries** (G1-G16 as applicable): site regeneration and G3 for every IMPLEMENT task; the
  same-task rule and the findings bullet (G9); the G6 suite search, widened to `.github/workflows/` so a retired suite
  leaves `SUITES` in the task that retires it, for every task that deletes a file (317-323, 325, 326); the count
  re-sync in the three wrapper-deletion tasks; the research task's owner classes and G2 table; the G2 sweep in
  task-329; the KB-coexistence block (row 10 of the delivery-010 light review) in every DOCUMENT task; no new skill
  folder, so G14 does not apply.
- **Same-file and cross-assert order is an edge (G4, G12):** `test-deploy-monitor-repurpose.sh` (314, 318, 319, 320,
  326 in a chain); `rules.md`, `test-skill-guide.sh`, `deferred.tsv`, the catalog rows, the counting suites and the doc
  counts (318 -> 319 -> 320, then 333 -> 334 for `deferred.tsv`); `test-work-initiation-gate.sh` (320 -> 321);
  `test-artifact-discipline.sh` (321 -> 322 -> 323); the connector and ticket suites (313 -> 319 -> 321);
  `consumption-protocol.md` (319 -> 321 -> 329); the dashboard parity test (326 -> 328 -> 331);
  `generate-profile/SKILL.md` (325 -> 329); the site (316 -> 317 -> 318). The remaining `g12scan.py` hits are
  `SKILL.md` files of different skills, or a file one task only names.

---

## 3. Tasks

`Source` reads `feature-009-one-skill-per-need -> delivery-012 -> AC-...`.

### task-311: Delivery-012 site search and reconciled edit list [RESEARCH]

- **Stanza wave:** 1. **Depends on:** --.
- **Source:** AC-20, AC-31.
- **Scope:**
  - Create `.aid/works/work-003-full-aid-restructure/research/delivery-012-sites.md`. Touch nothing else.
  - Re-run these searches at this task's base commit, and record the base commit in the file
    (REQUIREMENTS.md § 11 Feature 009 `##### 1. Files and layout` and `##### 8. Migration`):
    - **B1** both `git grep` commands of REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, Suites, verbatim, read hit by hit, each hit with
      the class the spec gives it (retired, rewritten, re-pointed, unchanged, dashboard, site);
    - **B2** the re-pointing sites: every kept file under `canonical/`, `.claude/skills/generate-profile/`,
      `scripts/checks/`, `bin/aid`, `bin/aid.ps1` and `dashboard/` that names a skill this delivery retires, the engine,
      the shortcut catalog, a scaffolding file, `build-shortcut-skills.py` or `IMPEDIMENT.md` (the spec's list of sites
      is the minimum, not the whole). `aid-config` hits are delivery-013's, and `canonical/aid/scripts/migrate/` is
      exempt;
    - **B3** the full list of skill folders this delivery deletes, from `ls -d canonical/skills/aid-*/`: every
      remaining `aid-create-*`, `aid-update-*`, `aid-document-*` and `aid-test-*`, and `aid-prototype-ui`,
      `aid-remove`, `aid-deprecate`, `aid-migrate`, `aid-experiment`; each with whether it is a generated doorway or
      hand-authored, and the task that deletes it (task-318, task-319 or task-320);
    - **B4** for each file this delivery deletes (the folders of B3, `shortcut-engine.md`, `shortcut-catalog.yml`,
      `shortcut-scaffolding/`, `feedback-artifacts/`, `build-shortcut-skills.py`, the site's engine, sibling and doorway
      modules), every reader in `tests/`, `site/`, `dashboard/`, `.github/` and `scripts/`, and the clause or check
      that reads it;
    - **B5** the rows of `tests/conversation/deferred.tsv`, `tests/canonical/skill-steps-exempt.tsv`, the SG-04
      description exempt list and the `SUITES` list of `installer-tests.yml` that name a retired skill, a retired
      suite or the engine;
    - **B6** the format-6 conversion rows in `bin/aid` and `bin/aid.ps1` that name a retired skill (Feature 003's
      initiator rows, Feature 006's type and document rows), which the markers must wrap;
    - **B7** the impediment sites of `aid-research`, `aid-review` and `aid-report`, and every suite that asserts them.
  - Give each hit exactly one owner:
    - a task of delivery-012 (task-312 to task-337; see the task files under
      `.aid/works/work-003-full-aid-restructure/tasks/task-NNN/DETAIL.md`, the layout delivery-008's migration leaves);
    - delivery-013, for a hit on `aid-config`, `.aid/kinds/`, the `domain` field, the identity statement or the kind
      hooks of `aid-review`, `aid-research` and `aid-report`;
    - delivery-014, for a hit under `docs/`, `site/src/content/docs/` (outside the generated skill pages),
      `README.md` (outside the counted phrases) or `examples/`;
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
  - [ ] Each of B1-B7 shows its exact command, and re-running it at the base named in the file reproduces its hits.
  - [ ] Every hit has exactly one owner; the count of rows with an empty owner cell is 0; B3 lists every folder `ls -d canonical/skills/aid-{create,update,document,test}-*/ canonical/skills/aid-{prototype-ui,remove,deprecate,migrate,experiment}/` prints at the base.
  - [ ] The skill owner table has exactly one row per `canonical/skills/*/SKILL.md` on disk at the base (the row count equals `ls canonical/skills/*/SKILL.md | wc -l`), and no row is unowned.
  - [ ] RESEARCH defaults are overridden as in task-001; the test step selects nothing (work folder only).

### task-312: The tracker procedures: connectors/ticket-create.md and ticket-update.md [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-311.
- **Source:** AC-20, AC-30.
- **Scope:**
  - Create `canonical/aid/templates/connectors/ticket-create.md` and `ticket-update.md`, type `template-own`
    (REQUIREMENTS.md § 11 Feature 009 `##### 1. Files and layout`): the tracker procedures moved out of `aid-create-ticket` and `aid-update-ticket`,
    unchanged in substance -- connector resolution, the preview, the confirmation, and Feature 001's `attachment`
    part (Q100). The two skills keep working until task-319 retires them.
  - Suites to update in this same task: any suite the findings' B1 assigns here.
- **Acceptance criteria:**
  - [ ] Both files exist; each names the connector resolution, the preview and the confirmation, and `ticket-update.md` names the `attachment` part.
  - [ ] A side-by-side read against the two skills' `SKILL.md` finds every tracker step carried over: no step of the skills is missing from the procedures (listed in the task's report).

### task-313: The TICKET step and the ticket kind of /aid-create and /aid-update [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-312.
- **Source:** AC-20, AC-30.
- **Scope:**
  - `canonical/skills/aid-create/SKILL.md` and `canonical/skills/aid-update/SKILL.md` (REQUIREMENTS.md § 11 Feature 009 `##### 2. Flow`): the step
    table gains TICKET (`connectors/ticket-create.md` / `ticket-update.md`, main conversation, `ASK` -> TICKET for the
    preview and its confirmation; `HALT`), and START's advance gains `CHAIN` -> TICKET for a ticket. Outside a work
    TICKET creates no work and asks with `--ask --project`; inside a work it is a `CALL` (`--handoff --to aid-update
    --step TICKET --returns yes --why 'write back: <ref>'`), and the write is recorded in `write_backs`. Each file stays
    within 80 lines.
  - `canonical/aid/templates/kind-catalog.yml`: the `ticket` kind (`taken_by: 'create, update'`, `next: tracker`).
  - `canonical/aid/templates/action-start.md` step 4: a ticket creates no work; `CHAIN` -> TICKET.
  - Suites to update in this same task (Q106; REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, Rewritten):
    `test-ticket-skills-structural.sh` is rewritten over `connectors/ticket-create.md`, `ticket-update.md` and the
    `ticket` kind of `/aid-create` and `/aid-update` (its `aid-read-ticket` sibling checks follow);
    `test-ticket-retirement-structural.sh`'s ticket-skill paths become the two connector procedures (its engine-seam
    assertions go with the engine, task-321); `test-actions.sh` group A where AS-03 or AS-04 reads these files; any
    suite the findings' B1 assigns here.
- **Acceptance criteria:**
  - [ ] `aid-create` and `aid-update` `SKILL.md` each have a TICKET row naming its connector procedure, and stay within 80 lines; `kind-catalog.yml` has `kind: ticket` with `next: tracker`; `action-start.md` names TICKET.
  - [ ] The TICKET references name the preview and the confirmation (AS-06's ticket half); `test-ticket-skills-structural.sh`, `test-ticket-retirement-structural.sh` and `test-actions.sh` pass where the test step puts them.

### task-314: Free-form text after /aid-deploy and /aid-monitor is a plain request [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-311.
- **Source:** AC-20, AC-31.
- **Scope:**
  - `canonical/skills/aid-deploy/SKILL.md` and `canonical/skills/aid-monitor/SKILL.md`, Step 0 and § Argument-Hint
    (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, `/aid-deploy` and `/aid-monitor` free-form text): text after the command is handed to
    Feature 001's intake (`/aid-orchestrate`, `check-intent.md`), which routes it to the matching skill; the branch
    creates no work of its own; a bare command keeps its own flow. Neither file names the engine or the shortcut
    catalog.
  - Suites to update in this same task (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`): `test-deploy-monitor-repurpose.sh` DMR20a and
    DMR20b rewritten (Step 0 hands free-form text to the intake and names no engine), DMR20c rewritten (the free-form
    branch creates no work of its own), DMR21, DMR22, DMR23 and their fixture (a work the engine halted at approval)
    retired; `test-downstream-worktree-entry.sh` G6 checks that the free-form region names the intake, not
    `shortcut-engine.md`; any suite the findings' B1 assigns here.
- **Acceptance criteria:**
  - [ ] Over the two `SKILL.md` files, `grep -nE 'shortcut-engine|shortcut-catalog'` prints nothing, and each Step 0 names `aid-orchestrate` (AS-04's `aid-deploy` / `aid-monitor` clause).
  - [ ] `test-deploy-monitor-repurpose.sh` and `test-downstream-worktree-entry.sh` pass in the scratch copy (both are copy-reading), with DMR21-DMR23 gone and their accepted-removal rows.

### task-315: No impediment file: the per-row choice in aid-research, aid-review and aid-report [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-311.
- **Source:** AC-20, AC-28.
- **Scope:**
  - `canonical/skills/aid-research/SKILL.md`, `aid-review/SKILL.md` and `aid-report/SKILL.md` (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`,
    No impediment file): the three-cycle limits that write an impediment become Feature 005's rule (Q69): after three
    rounds below the bar, each open row is one question -- fix it, accept it as is, or keep reviewing; no
    `IMPEDIMENT-*.md` is written and `lifecycle` is never set `Blocked` by these skills; their boundary lines name the
    new skills (`/aid-test` for checks, `/aid-prototype` for spikes, the `experiment` kind) instead of the retired ones.
  - Their kind hooks are delivery-013's.
  - Suites to update in this same task: every suite the findings' B7 lists, and any suite the findings' B1 assigns
    here.
- **Acceptance criteria:**
  - [ ] Over the three skills, `git grep -nE 'IMPEDIMENT|lifecycle: Blocked'` finds nothing, and each names the three choices (fix, accept, keep reviewing).
  - [ ] The suites of B7 pass where the test step puts them, and the site `npm test` passes after regeneration.

### task-316: Site generator: the skill list from canonical/skills/ [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-311.
- **Source:** AC-31.
- **Scope:**
  - REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, Site and its check-by-check list, the `skills/` part:
    - `site/scripts/skills/catalog.mjs` is rewritten: the skill list comes from `canonical/skills/*/SKILL.md`, never
      from `shortcut-catalog.yml`;
    - `groups.mjs` and `curated-roster.mjs`: groups in the skill guide's order (while `<kind>` lines exist, a folder the
      guide reaches only through one is grouped under that line); no "unassignable skill" for a skill that is not a
      catalog row;
    - `skill-counts.mjs`: counts from the folders; no catalog-row or doorway count;
    - `discover.mjs`, `paths.mjs`, `render-index.mjs`, `gen-skills.mjs` (`INDEX_SRC` and the generated-from strings name
      `canonical/skills/*/SKILL.md` only);
    - `gen-reference.mjs`: the engine and catalog rows go, and the skills page no longer reads either file;
    - their tests: `skills-catalog.test.mjs`, `skills-groups.test.mjs`, `skill-counts.test.mjs`, `gen-skills.test.mjs`,
      `gen-skills-index.test.mjs`, `gen-reference.test.mjs`, `skills-paths.test.mjs`, `skills-body.test.mjs`,
      `skills-render-index.test.mjs`, `skills-render-page.test.mjs`.
  - After this task no site module reads `shortcut-catalog.yml` or `shortcut-engine.md` for the skill list or the
    reference pages (the flow-graph modules are task-317).
- **Acceptance criteria:**
  - [ ] Over `site/scripts/skills/` and `site/scripts/gen-reference.mjs`, `git grep -nE 'shortcut-catalog|shortcut-engine'` finds nothing.
  - [ ] `(cd site && npm test)` passes, and `npm run gen:skills && npm run gen:reference` regenerates the pages with every skill folder on disk listed.

### task-317: Site generator: the flow graph without doorways, engine or siblings [IMPLEMENT]

- **Stanza wave:** 2. **Depends on:** task-316.
- **Source:** AC-31.
- **Scope:**
  - REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, Site, the flow-graph and provenance part:
    - retired with their modules: `site/scripts/lib/flow-graph/engine-core.mjs`, `extract-engine.mjs`,
      `extract-sibling.mjs`, and `flow-engine-core.test.mjs`, `flow-extract-engine.test.mjs`,
      `flow-extract-sibling.test.mjs`, `flow-graph-doorways.test.mjs`;
    - rewritten: `lib/flow-graph/classify.mjs` (no doorway or sibling class) with `flow-classify.test.mjs`;
    - re-pointed (names, paths and fixtures): `lib/flow-graph/compose.mjs`, `advance.mjs`, `extract-residual.mjs`,
      `lib/provenance/index.mjs`, `verify.mjs`, `gen-skills.mjs`'s flow-class list, and the tests `flow-compose`,
      `flow-graph`, `flow-facade`, `flow-extract-residual`, `flow-extract-inline`, `flow-advance`,
      `provenance-appender`, `provenance-deep-link` (`.test.mjs`), and `site/src/lib/__tests__/feature-006-head-gate.test.ts`
      and `skill-node-panel.test.ts` (their `generatedFrom` strings name `canonical/skills/*/SKILL.md` only).
  - A doorway skill still on disk is drawn by the residual extractor until task-318 and task-320 delete it.
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
    - The same search also runs over `.github/workflows/`: a suite this task retires leaves the `SUITES` list of
      `installer-tests.yml` in this same task, and its assertions get their rows in
      `tests/coverage-accepted-removals.tsv`.
- **Acceptance criteria:**
  - [ ] The seven retired files are gone; over `site/scripts/` and `site/src/lib/`, `git grep -nE 'engine-doorway|sibling-doorway|shortcut-engine|build-shortcut-skills'` finds nothing outside the generated pages.
  - [ ] `(cd site && npm test)` passes, and `npm run gen:skills` regenerates every flow with no error.

### task-318: The generated wrapper skills retired [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-314, task-316, task-317.
- **Source:** AC-20, AC-31.
- **Scope:**
  - Delete the generated doorway folders that remain (REQUIREMENTS.md § 11 Feature 009 `##### 1. Files and layout`, Delete; the findings' B3):
    `aid-create-<k>` and `aid-update-<k>` for the code kinds, `test` and `dashboard`, and `aid-remove`,
    `aid-deprecate`, `aid-migrate`, `aid-experiment`.
  - **Lists that follow a retired skill**, in this same task, for every folder it deletes: its rows in the SG-04
    description exempt list of `tests/canonical/test-skill-guide.sh` (SG-04 fails while an exempt skill is gone);
    its `skill:` rows in `tests/conversation/deferred.tsv` (DT-01 needs each to match a folder) and in
    `tests/canonical/skill-steps-exempt.tsv`; its row in `shortcut-catalog.yml` (`test-catalog-dirs-parity.sh` and
    DMR35b need every row to have its folder), with the counting suites (DMR30-DMR35, `test-shortcut-builder-invariants.sh`,
    `test-catalog-dirs-parity.sh`, `test-doc-counts.sh`) taking the new counts; the site roster.
  - **The skill guide follows the folders on disk:** each `canonical/aid/rules.md` § Skill guide `<kind>` line names
    only kinds that still have a folder, and a family with no folder left loses its line, so SG-02 holds at this
    task's end.
  - The family-scaffold suites retire here, with accepted-removal rows (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, Retired: their rules
    live in the catalog since delivery-011): `test-create-family-scaffold.sh`, `test-change-refactor-family-scaffold.sh`,
    `test-fix-family-scaffold.sh`, `test-document-family-scaffold.sh`, `test-prototype-family-scaffold.sh`,
    `test-test-experiment-family-scaffold.sh`.
  - **Count re-sync (Q134 D5):** the skill-count and catalog-row phrases that `tests/canonical/test-doc-counts.sh`
    asserts in `README.md` and `docs/` take the derived counts, then `(cd site && npm run sync:docs)` runs, so the
    synced pages under `site/src/content/docs/` match. Only the numbers change; user documentation otherwise waits
    for the final pass (AC-45).
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
    - The same search also runs over `.github/workflows/`: a suite this task retires leaves the `SUITES` list of
      `installer-tests.yml` in this same task, and its assertions get their rows in
      `tests/coverage-accepted-removals.tsv`.
- **Acceptance criteria:**
  - [ ] `ls -d canonical/skills/aid-{create,update}-*/ 2>/dev/null` lists only the hand-authored folders task-319 and task-320 retire, and `aid-remove`, `aid-deprecate`, `aid-migrate` and `aid-experiment` are absent; no catalog row names a deleted folder.
  - [ ] `test-skill-guide.sh`, `test-deploy-monitor-repurpose.sh`, `test-catalog-dirs-parity.sh` and `test-shortcut-builder-invariants.sh` pass where the test step puts them, DT-01 passes, `test-doc-counts.sh` passes live with the skill count lowered, the six family-scaffold suites are gone with their rows, and the site `npm test` passes after `sync:docs` and regeneration.

### task-319: The ticket skills retired, and the ticket seams re-pointed [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-313, task-318.
- **Source:** AC-20, AC-31.
- **Scope:**
  - Delete `canonical/skills/aid-create-ticket/` and `canonical/skills/aid-update-ticket/` (REQUIREMENTS.md § 11 Feature 009 `##### 1. Files and
    layout`).
  - **Lists that follow a retired skill**, in this same task, for every folder it deletes: its rows in the SG-04
    description exempt list of `tests/canonical/test-skill-guide.sh` (SG-04 fails while an exempt skill is gone);
    its `skill:` rows in `tests/conversation/deferred.tsv` (DT-01 needs each to match a folder) and in
    `tests/canonical/skill-steps-exempt.tsv`; its row in `shortcut-catalog.yml` (`test-catalog-dirs-parity.sh` and
    DMR35b need every row to have its folder), with the counting suites (DMR30-DMR35, `test-shortcut-builder-invariants.sh`,
    `test-catalog-dirs-parity.sh`, `test-doc-counts.sh`) taking the new counts; the site roster.
  - **The skill guide follows the folders on disk:** each `canonical/aid/rules.md` § Skill guide `<kind>` line names
    only kinds that still have a folder, and a family with no folder left loses its line, so SG-02 holds at this
    task's end.
  - Re-point the ticket sites (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, Re-pointing), so nothing names the two skills:
    `connectors/consumption-protocol.md` (the ticket seams: the two connector procedures), `connectors/ticket-resolution.md`,
    `aid-read-ticket` (its sibling lines), `aid-set-connector`, `aid-unset-connector`, `aid-orchestrate`'s
    `external-sources.md`, `aid-monitor-pipeline`'s `close.md` (`/aid-update-ticket` -> `/aid-update ticket`), and every
    other kept file under `canonical/` that names either skill (outside `canonical/aid/scripts/migrate/`); task-329's
    sweep then finds no ticket-skill name left.
  - Suites to update in this same task: `test-connector-consumption-linkage.sh` (the seams follow
    `consumption-protocol.md`'s table), `test-connector-skills-structural.sh`, `test-ticket-skills-structural.sh`,
    `test-ticket-retirement-structural.sh`, `test-monitor-pipeline.sh` where it reads `close.md`, and any suite the
    findings' B1 or B4 assigns here.
  - **Count re-sync (Q134 D5):** the skill-count and catalog-row phrases that `tests/canonical/test-doc-counts.sh`
    asserts in `README.md` and `docs/` take the derived counts, then `(cd site && npm run sync:docs)` runs, so the
    synced pages under `site/src/content/docs/` match. Only the numbers change; user documentation otherwise waits
    for the final pass (AC-45).
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
    - The same search also runs over `.github/workflows/`: a suite this task retires leaves the `SUITES` list of
      `installer-tests.yml` in this same task, and its assertions get their rows in
      `tests/coverage-accepted-removals.tsv`.
- **Acceptance criteria:**
  - [ ] Both folders are gone; over `canonical/`, `git grep -nE 'aid-(create|update)-ticket'` finds nothing outside `canonical/aid/scripts/migrate/`.
  - [ ] The connector and ticket suites pass where the test step puts them, DT-01 and SG-04 pass, `test-doc-counts.sh` passes live, and the site `npm test` passes after `sync:docs` and regeneration.

### task-320: The document, test and prototype wrappers retired, and the guide's <kind> lines gone [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-319.
- **Source:** AC-20, AC-31.
- **Scope:**
  - Delete `canonical/skills/aid-create-document/`, `aid-update-document/`, `aid-create-diagram/`, every
    `aid-document-*/`, every `aid-test-*/` and `aid-prototype-ui/` (REQUIREMENTS.md § 11 Feature 009 `##### 1. Files and layout`; the findings'
    B3).
  - **Lists that follow a retired skill**, in this same task, for every folder it deletes: its rows in the SG-04
    description exempt list of `tests/canonical/test-skill-guide.sh` (SG-04 fails while an exempt skill is gone);
    its `skill:` rows in `tests/conversation/deferred.tsv` (DT-01 needs each to match a folder) and in
    `tests/canonical/skill-steps-exempt.tsv`; its row in `shortcut-catalog.yml` (`test-catalog-dirs-parity.sh` and
    DMR35b need every row to have its folder), with the counting suites (DMR30-DMR35, `test-shortcut-builder-invariants.sh`,
    `test-catalog-dirs-parity.sh`, `test-doc-counts.sh`) taking the new counts; the site roster.
  - **The skill guide** (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`): the `<kind>` lines go, and `test-skill-guide.sh` SG-02 matches
    `canonical/skills/` both ways with no expansion (AS-08 holds at this task's end). Every guide line stays within
    SG-03's limit.
  - Suites to update in this same task (Q106): `test-work-initiation-gate.sh` Group G drops `aid-create-document` and
    `aid-update-document` (with their `STARTER_ALLOC_ANCHOR` and `STARTER_COVERAGE_ID` entries; the counts G and GG00
    follow); `test-state-review-surface.sh` where it reads these skills; any suite the findings' B1 or B4 assigns here.
  - `skill:aid-document` and `skill:aid-prototype` stay in `deferred.tsv`: those skills stay, and task-333's samples
    cover them.
  - **Count re-sync (Q134 D5):** the skill-count and catalog-row phrases that `tests/canonical/test-doc-counts.sh`
    asserts in `README.md` and `docs/` take the derived counts, then `(cd site && npm run sync:docs)` runs, so the
    synced pages under `site/src/content/docs/` match. Only the numbers change; user documentation otherwise waits
    for the final pass (AC-45).
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
    - The same search also runs over `.github/workflows/`: a suite this task retires leaves the `SUITES` list of
      `installer-tests.yml` in this same task, and its assertions get their rows in
      `tests/coverage-accepted-removals.tsv`.
- **Acceptance criteria:**
  - [ ] `ls -d canonical/skills/aid-*/ | grep -E 'aid-(create|update|design|document|test|prototype)-'` prints nothing, and `aid-remove`, `aid-deprecate`, `aid-migrate` and `aid-experiment` are absent (AS-01 without its `aid-configure` clause).
  - [ ] `grep -c '<kind>' canonical/aid/rules.md` prints 0; `test-skill-guide.sh` and `test-work-initiation-gate.sh` pass where the test step puts them, DT-01 passes, `test-doc-counts.sh` passes live, and the site `npm test` passes after `sync:docs` and regeneration.

### task-321: The shortcut engine retired, and the shared exempt list empty [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-313, task-314, task-316, task-317, task-320.
- **Source:** AC-20.
- **Scope:**
  - Delete `canonical/aid/templates/shortcut-engine.md` (REQUIREMENTS.md § 11 Feature 009 `##### 1. Files and layout`; What replaces the engine).
  - `tests/canonical/skill-steps-exempt.tsv` loses the `shortcut-engine.md` row (`SP-08`, `PL-06`) and ends empty
    (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, Lists).
  - Suites to update in this same task (Q106 applied to deletions; REQUIREMENTS.md § 11 Feature 009 `##### 6`, the rows owed by Features 002, 005,
    006 and 007): `test-shortcut-engine-contract.sh` retired; `test-skill-steps.sh` SS-02, SS-04 and SS-09 drop their
    engine clauses ("while it exists"); `test-specify.sh` SP-08 and `test-plan.sh` PL-06 drop the engine; `test-execute.sh`
    EX-06's APPROVAL-HALT check goes; `test-state-review-surface.sh` loses the engine's GATE surface and its
    missing-file guard; `test-artifact-discipline.sh` AD07 and AD08 drop `shortcut-engine.md` from their scan lists;
    `test-work-initiation-gate.sh` Group G drops `shortcut-engine.md` (the counts follow);
    `test-connector-consumption-linkage.sh` loses the engine's intake seam from its seam count;
    `test-ticket-retirement-structural.sh` loses its engine-seam assertions; `consumption-protocol.md`'s engine seam row
    goes; any suite the findings' B4 assigns here.
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
    - The same search also runs over `.github/workflows/`: a suite this task retires leaves the `SUITES` list of
      `installer-tests.yml` in this same task, and its assertions get their rows in
      `tests/coverage-accepted-removals.tsv`.
- **Acceptance criteria:**
  - [ ] `test -e canonical/aid/templates/shortcut-engine.md` fails; `tests/canonical/skill-steps-exempt.tsv` holds no data row.
  - [ ] Every suite named in the scope passes where the test step puts it, `test-shortcut-engine-contract.sh` is gone with its rows, and over the files this task changes, `git grep -n 'shortcut-engine'` finds nothing.

### task-322: The shortcut scaffolding retired [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-321.
- **Source:** AC-20.
- **Scope:**
  - Delete `canonical/aid/templates/shortcut-scaffolding/` (REQUIREMENTS.md § 11 Feature 009 `##### 1. Files and layout`): its rules live in the
    catalog since delivery-011.
  - Suites to update in this same task: `test-artifact-discipline.sh` AD07 and AD08 drop `shortcut-scaffolding/` from
    their scan lists, and a group left with nothing to scan retires; any suite the findings' B4 assigns here.
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
    - The same search also runs over `.github/workflows/`: a suite this task retires leaves the `SUITES` list of
      `installer-tests.yml` in this same task, and its assertions get their rows in
      `tests/coverage-accepted-removals.tsv`.
- **Acceptance criteria:**
  - [ ] `test -e canonical/aid/templates/shortcut-scaffolding` fails.
  - [ ] `test-artifact-discipline.sh` passes where the test step puts it, and over the files this task changes `git grep -n 'shortcut-scaffolding'` finds nothing.

### task-323: The impediment template retired [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-315, task-322.
- **Source:** AC-20.
- **Scope:**
  - Delete `canonical/aid/templates/feedback-artifacts/` (`IMPEDIMENT.md`, its only file): task-315 removed its last
    users (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, No impediment file).
  - Every kept file under `canonical/` that names `feedback-artifacts/` (outside `canonical/aid/scripts/migrate/`) is
    re-pointed in this same task; a plain `IMPEDIMENT-*.md` mention of an old work's file is task-329's.
  - `dashboard/reader/tests/test_derivation.py` stays: its `task-NNN/IMPEDIMENT.md` is an old work's file the reader
    still meets, not the deleted template.
  - Suites to update in this same task: any suite the findings' B4 assigns here.
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
    - The same search also runs over `.github/workflows/`: a suite this task retires leaves the `SUITES` list of
      `installer-tests.yml` in this same task, and its assertions get their rows in
      `tests/coverage-accepted-removals.tsv`.
- **Acceptance criteria:**
  - [ ] `test -e canonical/aid/templates/feedback-artifacts` fails, and over `canonical/` `git grep -n 'feedback-artifacts'` finds nothing outside `canonical/aid/scripts/migrate/`.
  - [ ] The suites the findings name pass where the test step puts them.

### task-324: KB type registry: the generated-skill type retired [DOCUMENT]

- **Stanza wave:** 3. **Depends on:** task-320.
- **Source:** AC-20.
- **Scope:**
  - `.aid/knowledge/authoring-conventions.md` (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, KB): the `skill-generated` type and its
    criterion SK-02 retire with the last generated skill; `skill-authored`'s selector becomes any
    `canonical/skills/*/SKILL.md`, without `name-in`; the sentences that count the expressible rows and explain the
    ordering follow. This comes before the catalog's deletion (task-326), whose name the old selector reads.
  - Name no work and no work folder.
  - **KB edits and NEXT's KB check (Feature 007 § 2, step 7; Feature 004).** After every earlier task of this
    delivery, NEXT's KB check may make a `CALL` to `/aid-kb-update`, which edits and commits the drifted documents
    itself (`kb-commit.sh`) and records a `KB change` entry `Assumed`. This task is the delivery's planned KB edit, and
    it runs on the KB those calls left: before editing, it reads this work's `kb_updates` and its `KB change` entries;
    it keeps what they wrote that agrees with the spec, adds only what the spec's KB list still lacks, and changes their
    text only where it contradicts the spec, naming the entry it corrects. It commits through `kb-commit.sh`. Its
    commits touch no document's `sources:`, so NEXT's KB check after it finds nothing to do.
- **Acceptance criteria:**
  - [ ] The registry has no `skill-generated` row and no SK-02, and `skill-authored`'s Match column is `path canonical/skills/*/SKILL.md`.
  - [ ] `bash scripts/checks/g07-selector-partition.sh` exits 0, `test-criterion-oracles.sh` passes where the test step puts it; no work id, and the lints pass.

### task-325: The doorway builder retired, and generate-profile counting from the folders [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-320.
- **Source:** AC-20.
- **Scope:**
  - Delete `.claude/skills/generate-profile/scripts/build-shortcut-skills.py`: no generated skill remains
    (REQUIREMENTS.md § 11 Feature 009 `##### 1. Files and layout`).
  - `.claude/skills/generate-profile/SKILL.md`: the builder steps and the catalog-derived counts go; skills are counted
    from `canonical/skills/`.
  - Suites to update in this same task: `test-shortcut-builder-invariants.sh` retired; `test-dogfood-byte-identity.sh`
    where it reads `generate-profile/SKILL.md`; any suite the findings' B4 assigns here.
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
    - The same search also runs over `.github/workflows/`: a suite this task retires leaves the `SUITES` list of
      `installer-tests.yml` in this same task, and its assertions get their rows in
      `tests/coverage-accepted-removals.tsv`.
- **Acceptance criteria:**
  - [ ] `test -e .claude/skills/generate-profile/scripts/build-shortcut-skills.py` fails, and `generate-profile/SKILL.md` names neither the builder nor `shortcut-catalog.yml`.
  - [ ] `test-dogfood-byte-identity.sh` passes in the scratch copy, and `test-shortcut-builder-invariants.sh` is gone with its rows.

### task-326: The shortcut catalog retired, with its counting suites [IMPLEMENT]

- **Stanza wave:** 3. **Depends on:** task-321, task-322, task-324, task-325.
- **Source:** AC-20, AC-31.
- **Scope:**
  - Delete `canonical/aid/templates/shortcut-catalog.yml` (REQUIREMENTS.md § 11 Feature 009 `##### 1. Files and layout`).
  - Suites to update in this same task (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, Suites; `##### 6`, the rows owed by Features 003 and
    004):
    - `test-deploy-monitor-repurpose.sh`: DMR00e and DMR30-DMR35 retired; DMR24 re-pointed (the two skills carry no
      `GENERATED` marker), DMR33 re-pointed (no `canonical/skills/*/SKILL.md` carries one), DMR36 re-pointed (every
      skill folder has a skill-guide line, as SG-02 does);
    - `test-catalog-dirs-parity.sh` retired;
    - `test-doc-counts.sh` rewritten: counts from `canonical/skills/`, not catalog rows;
    - `test-kb-skills.sh` KB-01 and `test-idea-shaping.sh` ID-03, which name the catalog only while it exists;
    - `test-connector-skills-structural.sh`: its check that the connector skills have no catalog row retires;
    - `dashboard/reader/tests/test_shortcut_kind_map_cross_runtime_parity.py`: Leg 3 (every catalog row has a key) and
      its control `test_p1b` retire; Legs 1, 2 and 4 stay;
    - any suite the findings' B4 assigns here.
  - **Suites that read what this task deletes, moves or renames (G6).** For each such file and folder,
    build the list with `git grep -l -e '<path>' -e '<folder>/' -- tests/ site/` at this task's base. The
    list does not come from the findings' map alone. Every suite it finds is updated in this same task
    (Q106 applied to deletions). Any exemption row this task's own criteria need is created here, or the
    criterion is scoped so it holds without the row.
    - The same search also runs over `.github/workflows/`: a suite this task retires leaves the `SUITES` list of
      `installer-tests.yml` in this same task, and its assertions get their rows in
      `tests/coverage-accepted-removals.tsv`.
- **Acceptance criteria:**
  - [ ] `test -e canonical/aid/templates/shortcut-catalog.yml` fails, and over `tests/canonical/*.sh` and `site/scripts/` `git grep -n 'shortcut-catalog'` finds nothing (the dashboard comments and docstrings are task-328's, and the baselines are re-recorded at the gate).
  - [ ] `test-deploy-monitor-repurpose.sh`, `test-kb-skills.sh`, `test-idea-shaping.sh` and `test-connector-skills-structural.sh` pass where the test step puts them, `test-doc-counts.sh` passes live, and `python3 -m pytest dashboard/reader/tests/test_shortcut_kind_map_cross_runtime_parity.py` passes.

### task-327: Format 6: the doorway rows, inside legacy-skill-names markers [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-326.
- **Source:** AC-25, AC-31.
- **Scope:**
  - The format-6 work-state step in `bin/aid` and its PowerShell twin in `bin/aid.ps1` (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`,
    Format 6), bash first then the twin in this same task, byte-identical, PowerShell 5.1-safe, ASCII and idempotent:
    - `intent.kind`, when missing, from the old initiator's name (`aid-create-<k>` / `aid-update-<k>` -> `k`;
      `aid-remove` / `aid-deprecate` / `aid-migrate` -> `removal` / `deprecation` / `migration`; `aid-document-<g>` ->
      `g`; `aid-create-diagram` -> `diagram`; `aid-document`, `aid-create-document`, `aid-update-document` -> `general`;
      `aid-test-<k>` -> `k`; `aid-experiment` -> `experiment`; `aid-prototype-ui` -> `ui`; otherwise `--`), with the
      precedence of the approved rows (Feature 004's KB rows, Feature 006's Q74 document types) and their excluded
      names;
    - the record fill's initiator rows, after the approved rows: `aid-create-*` -> `/aid-create`; `aid-update-*`,
      `aid-remove`, `aid-deprecate`, `aid-migrate` -> `/aid-update`; the document skills -> `/aid-document`;
      `aid-test-*`, `aid-experiment` -> `/aid-test`; `aid-prototype-ui` -> `/aid-prototype`; each at `START`;
    - the type (Q74), only where the name makes it certain;
    - a work halted at the engine's approval still goes to `/aid-execute`;
    - `legacy-skill-names: begin` / `end` comment markers wrap every row of the step that names a retired skill,
      whichever feature added it (Feature 003's initiator rows, Feature 006's type and document rows, these rows).
  - `tests/windows/Test-AidInstaller.ps1` gains a doorway-row case (Q126).
  - The unit cases are task-330.
  - Suites to update in this same task: `test-aid-cli-parity.sh`, `test-ps51-compat.sh`, `test-ascii-only.sh`, and any
    suite or case the findings' B6 assigns here.
- **Acceptance criteria:**
  - [ ] On a scratch repository at format 6, an `aid-create-api` work at `Specify` with no record gets `/aid-specify` with `kind: api`, and a second run changes nothing; under `pwsh` the twin gives byte-identical files.
  - [ ] Every line of the step in `bin/aid` and `bin/aid.ps1` that names a retired skill lies between `legacy-skill-names: begin` and `end`; `test-aid-cli-parity.sh` passes in the scratch copy, `test-ps51-compat.sh` and `test-ascii-only.sh` where the test step puts them, and the new `Test-AidInstaller.ps1` case passes under `pwsh` locally (5.1 runs in the Windows lane at G0).

### task-328: Dashboard: the legacy maps inside markers, and no retired name outside them [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-326.
- **Source:** AC-31.
- **Scope:**
  - `dashboard/reader/state_schema.py` and `dashboard/server/reader.mjs` (REQUIREMENTS.md § 11 Feature 009 `##### 5. Components`, Dashboard and
    chat): `SHORTCUT_KIND_MAP` and `_FULL_PATH_INITIATOR` stay, between `legacy-skill-names: begin` / `end` markers; their
    comments call the map a frozen list of old initiators, naming neither the catalog nor the builder.
  - Every other dashboard file (`home.html`, `dashboard/reader/*.py`, `dashboard/server/*.mjs`, `dashboard/server/*.py`)
    names no retired skill outside the markers; `aid-config` comments are delivery-013's. `chat-node/` needs no change.
  - `dashboard/reader/tests/test_work003_state_schema.py`: unchanged assertions; its docstrings stop naming the catalog.
  - The new parity check of the maps inside their markers is task-331.
  - Suites to update in this same task: the reader and server suites and fixtures the findings' B1 assigns here.
- **Acceptance criteria:**
  - [ ] In both files the map lies between the two markers, and over the dashboard files AS-07 lists, a search for the retired names (the findings' B3, without `aid-config`) outside the markers finds nothing.
  - [ ] `python3 -m pytest dashboard/reader/tests` and `node --test dashboard/server/tests` pass.

### task-329: Re-pointing: every kept file that names a retired skill, the engine or its files [IMPLEMENT]

- **Stanza wave:** 4. **Depends on:** task-319, task-323, task-325, task-326.
- **Source:** AC-20, AC-31.
- **Scope:**
  - One rule (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, Re-pointing): every kept file under `canonical/`, `.claude/skills/generate-profile/`
    and `scripts/checks/` that names a retired skill, the engine, the shortcut catalog, a scaffolding file,
    `build-shortcut-skills.py` or `IMPEDIMENT.md` is re-pointed to the skill or file that does the job now, or
    reworded. Exempt: `canonical/aid/scripts/migrate/` and text between `legacy-skill-names` markers. `aid-config` is
    delivery-013's.
  - The spec's sites, beyond those tasks 314, 315 and 319 own: `work-initiation-gate.md` and `work-state-template.yml`
    (the initiator examples), `subagent-heartbeat-protocol.md`, `grading-rubric.md`, `scripts/checks/review-path-audit.sh`,
    and every hit the findings' B2 assigns here.
  - **Skill owner table (G2).** The sweep owns every hand-written skill: it takes its list from
    `ls canonical/skills/*/SKILL.md` at this task's base, not from the findings' hits alone, and checks each skill's
    folder.
  - Suites to update in this same task: `test-review-path-audit.sh`, and any suite asserting a re-pointed line.
- **Acceptance criteria:**
  - [ ] Over `canonical/` (except `canonical/aid/scripts/migrate/`), `.claude/skills/generate-profile/` and `scripts/checks/`, outside `legacy-skill-names` markers, a search for the retired names of the findings' B3 and for `shortcut-engine|shortcut-catalog|shortcut-scaffolding|build-shortcut-skills|IMPEDIMENT\.md` finds nothing (AS-02's re-pointing rule, without `aid-config`).
  - [ ] `test-review-path-audit.sh` and the suites the findings name pass where the test step puts them, and the site `npm test` passes after regeneration.

### task-330: Migration cases: old doorway works [TEST]

- **Stanza wave:** 5. **Depends on:** task-327.
- **Source:** AC-25, AC-31, AC-37.
- **Scope:**
  - `tests/canonical/test-work-state-migration.sh` gains (REQUIREMENTS.md § 11 Feature 009 `##### 9. Testing`, Unit tests): an old `aid-create-api`
    work at `Specify` gets `/aid-specify` and `kind: api`; an `aid-document-runbook` work at the default phase gets
    `/aid-document` at START, kind `runbook`, type document; an `aid-create-api` work at the default phase gets
    `/aid-create` at START, kind `api`, type new capability; Feature 006's `aid-create-roadmap` fixture still gets
    `/aid-kb-update`, an `aid-create-document` work `/aid-document` with type document, and an `aid-update-kb` work kind
    `--`; an `aid-test-security` work gets `/aid-test`, type investigation; a work with a kind keeps it; a second run
    changes nothing; bash and PowerShell give the same bytes; every row naming a retired skill, Feature 003's and
    Feature 006's included, sits inside the `legacy-skill-names` markers.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-012-sites.md` assigns to `task-330`.
- **Acceptance criteria:**
  - [ ] The suite passes where the test step puts it, with each new case named.
  - [ ] Moving one row outside the markers in a scratch copy fails the marker case; changing one byte of the PowerShell output fails the byte-identity case.

### task-331: Dashboard: parity of the two legacy maps inside their markers [TEST]

- **Stanza wave:** 5. **Depends on:** task-328.
- **Source:** AC-31.
- **Scope:**
  - `dashboard/reader/tests/test_shortcut_kind_map_cross_runtime_parity.py` (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, Dashboard;
    `##### 9. Testing`): a new check finds both maps inside their `legacy-skill-names` markers, and Legs 1, 2 and 4 hold
    on the marked maps.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-012-sites.md` assigns to `task-331`.
- **Acceptance criteria:**
  - [ ] `python3 -m pytest dashboard/reader/tests/test_shortcut_kind_map_cross_runtime_parity.py` passes.
  - [ ] Moving either map outside its markers in a scratch copy fails the new check.

### task-332: test-actions.sh group B [TEST]

- **Stanza wave:** 5. **Depends on:** task-313, task-314, task-320, task-323, task-326, task-327, task-328, task-329.
- **Source:** AC-20, AC-30, AC-31.
- **Scope:**
  - `tests/canonical/test-actions.sh` gains group B (REQUIREMENTS.md § 11 Feature 009 `##### 9. Testing`; PLAN.md delivery-012 Scope): AS-01 without
    its `aid-configure` clause; AS-02 and AS-07 without `aid-config` (text between `legacy-skill-names` markers skipped);
    AS-04's `aid-deploy` / `aid-monitor` clause; AS-06's ticket half; AS-08. Group A stays as it is.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-012-sites.md` assigns to `task-332`.
- **Acceptance criteria:**
  - [ ] `test-actions.sh` passes where the test step puts it, groups A and B, with a named assertion per check.
  - [ ] Each new check fails its own mutation in a scratch copy: an `aid-create-api/` folder; `shortcut-engine.md` restored; `/aid-create-api` in a kept reference; a retired name in `home.html` outside the markers; `shortcut-engine` in `aid-deploy`'s Step 0; `ticket-create.md` without the preview; a `<kind>` line in the guide.

### task-333: Samples 009-06, 009-08, 009-09 and 009-10 (plain words, run at this gate) [TEST]

- **Stanza wave:** 5. **Depends on:** task-320, task-329.
- **Source:** AC-10, AC-28, AC-30.
- **Scope:**
  - Create under `tests/conversation/samples/feature-009/`, with frontmatter `skills:` the action skill, fixtures and the
    checks of REQUIREMENTS.md § 11 Feature 009 `##### 9. Testing`: `009-06-runbook-new-then-revised`, `009-08-experiment-is-a-test`,
    `009-09-prototype-ui`, `009-10-writing-tests-is-create`.
  - `tests/conversation/deferred.tsv`: `skill:aid-document` (covered by `009-06`) and `skill:aid-prototype` (covered by
    `009-09`) go.
  - Smoke run (Q134 D8): each sample once, in a scratch copy.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-012-sites.md` assigns to `task-333`.
- **Acceptance criteria:**
  - [ ] There are four files, each `covers` matches the spec's sample table, and no `## Answer sheet` names a skill; DT-01 and SS-09 pass with neither `skill:` row left.
  - [ ] Each smoke run has its result reported.

### task-334: Samples 009-11, 009-12, 009-14 and 009-16, the plain runs, and the deferred list [TEST]

- **Stanza wave:** 5. **Depends on:** task-313, task-315, task-327, task-333.
- **Source:** AC-1, AC-7, AC-14, AC-28, AC-29, AC-30, AC-36, AC-37.
- **Scope:**
  - Create `009-11-ticket-outside-a-work`, `009-12-ticket-write-back-in-a-work` (a scratch tracker reached through the
    tool's own connection), `009-14-old-doorway-work-after-update` and `009-16-research-three-rounds` under
    `tests/conversation/samples/feature-009/`, with the checks of REQUIREMENTS.md § 11 Feature 009 `##### 9. Testing`.
  - `tests/conversation/deferred.tsv` (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, Lists): the plain-run rows of `009-01`, `009-02` and
    `009-07` go; every remaining Feature 009 `skill:` row goes (covered by these samples, or gone with their skills);
    `009-11` and `009-12` get rows waiting for the integration run before release (delivery-014; the suite runs with no
    connection, Feature 001).
  - Smoke run (Q134 D8): `009-14`, `009-16`, the plain form of `009-01`, `009-02` and `009-07`, and the re-runs
    `001-01`, `001-07`, `003-02` and `008-14`, once each, in a scratch copy.
  - **Findings.** This task's scope also includes every site that
    `.aid/works/work-003-full-aid-restructure/research/delivery-012-sites.md` assigns to `task-334`.
- **Acceptance criteria:**
  - [ ] There are four new files; DT-01 and SS-09 pass, `deferred.tsv` holds no Feature 009 `skill:` row and no plain-run row, and `009-11` and `009-12` have their integration-run rows.
  - [ ] Each smoke run has its result reported.

### task-335: KB decisions, release notes, quality gates, roadmap and tech debt for one skill per need [DOCUMENT]

- **Stanza wave:** 5. **Depends on:** task-326, task-329.
- **Source:** AC-20, AC-24, AC-31.
- **Scope:**
  - Edit these documents under `.aid/knowledge/` (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, KB, and Release notes):
    - `decisions.md` gains "one skill per action, one catalog of kinds: a kind is data the phase skills read, typed or
      said", which supersedes D20 (the shortcut engine) and D22's scaffolding consequence, marked in the summary table
      and their sections;
    - `backlog.md` § Next Release: the old -> new rows for every slash name this delivery retires (the spec's Migration
      table, without `/aid-config`, and the typed command losing its one fast pass) (AC-24);
    - `quality-gates.md`: the "Shortcut / Lite-Path Gate (shortcut engine)" section and the engine in its `sources:`
      go; a `lite` work's quality is Specification's and Planning's graded checks;
    - `roadmap.md`: its shortcut-path sentences describe the action skills (`## Later` is delivery-013's);
    - `tech-debt.md`: W5-6 loses its `shortcut-engine.md` site, and W1-2's doorway split goes.
  - Name no work and no work folder.
  - **KB edits and NEXT's KB check (Feature 007 § 2, step 7; Feature 004).** After every earlier task of this
    delivery, NEXT's KB check may make a `CALL` to `/aid-kb-update`, which edits and commits the drifted documents
    itself (`kb-commit.sh`) and records a `KB change` entry `Assumed`. This task is the delivery's planned KB edit, and
    it runs on the KB those calls left: before editing, it reads this work's `kb_updates` and its `KB change` entries;
    it keeps what they wrote that agrees with the spec, adds only what the spec's KB list still lacks, and changes their
    text only where it contradicts the spec, naming the entry it corrects. It commits through `kb-commit.sh`. Its
    commits touch no document's `sources:`, so NEXT's KB check after it finds nothing to do.
- **Acceptance criteria:**
  - [ ] The new decision is in the summary table and its section, with D20 and D22 marked; `backlog.md` § Next Release has a row for each name of the findings' B3 and for each retired family form.
  - [ ] Over the edited documents, `git grep -nE 'shortcut-engine|shortcut-catalog|shortcut-scaffolding'` finds nothing outside superseded-decision text; no work id, and the citation and frontmatter lints pass.

### task-336: KB architecture, contracts, structure, schemas and glossary without the engine [DOCUMENT]

- **Stanza wave:** 5. **Depends on:** task-319, task-326, task-329, task-335.
- **Source:** AC-20, AC-31.
- **Scope:**
  - Edit these documents under `.aid/knowledge/` (REQUIREMENTS.md § 11 Feature 009 `##### 8. Migration`, KB): `capability-inventory.md`,
    `architecture.md`, `pipeline-contracts.md` (entry doors; the engine goes), `module-map.md`, `project-structure.md` (the
    scaffolding folder goes), `artifact-schemas.md` (the catalog as the one catalog; no shortcut catalog),
    `domain-glossary.md` (shortcut, doorway and kind sibling go), `infrastructure.md` (the ticket family is
    `/aid-read-ticket` plus the `ticket` kind of `/aid-create` and `/aid-update`, its sources the two connector
    procedures).
  - Name no work and no work folder.
  - **KB edits and NEXT's KB check (Feature 007 § 2, step 7; Feature 004).** After every earlier task of this
    delivery, NEXT's KB check may make a `CALL` to `/aid-kb-update`, which edits and commits the drifted documents
    itself (`kb-commit.sh`) and records a `KB change` entry `Assumed`. This task is the delivery's planned KB edit, and
    it runs on the KB those calls left: before editing, it reads this work's `kb_updates` and its `KB change` entries;
    it keeps what they wrote that agrees with the spec, adds only what the spec's KB list still lacks, and changes their
    text only where it contradicts the spec, naming the entry it corrects. It commits through `kb-commit.sh`. Its
    commits touch no document's `sources:`, so NEXT's KB check after it finds nothing to do.
- **Acceptance criteria:**
  - [ ] Over the edited documents, `git grep -nE 'shortcut-engine|shortcut-catalog|shortcut-scaffolding|doorway'` finds nothing, and each statement matches `canonical/` as this delivery leaves it.
  - [ ] No work id, and the lints pass.

### task-337: KB test landscape for one skill per need, the regenerated index and the view [DOCUMENT]

- **Stanza wave:** 5. **Depends on:** task-324, task-330, task-331, task-332, task-334, task-335, task-336.
- **Source:** AC-20, AC-31.
- **Scope:**
  - `.aid/knowledge/test-landscape.md`: `test-actions.sh` group B; the retired suites (the engine contract, the builder
    invariants, the catalog parity, the six family scaffolds) go; the rewritten and re-pointed suites; the migration
    cases; the doorway and `alias_of` counts go.
  - Then regenerate `INDEX.md` and render `kb.html` with the installed scripts (G0). This delivery's resync changes no
    KB document.
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
    1. **The run pauses** at the delivery-012 MILESTONE approval question, written `Pending` with `--ask`; the main
       conversation ends the session there.
    2. **Resync session:** the resync (`delivery-012: resync`), committed alone. Its `aid update` removes the retired
       skills, the engine, the catalog, the scaffolding and `feedback-artifacts/` through the install manifest, and its
       format-6 step runs the doorway rows (no work of this repository is a doorway work). Then the session ends.
    3. **Gate session, before the gate (G8):** the installed `derive-waves.sh --plan --check` on this work, with
       `--plan` when stale; `(cd site && npm run gen:reference)` and the site `npm test`, committing any regenerated
       page (`reference/settings.md` from `.aid/settings.yml`); a no-op when the resync changed nothing it reads. The KB
       is not changed by this resync.
    4. **The gate:** the stanza's criteria, the samples (the plain form of `009-01`, `009-02` and `009-07`; `009-06`,
       `009-08`, `009-09`, `009-10`, `009-14`, `009-16`; again `001-01`, `001-07`, `003-02`, `008-14`; each 3 of 3) and G0
       on the head, G0's lane item carried by the milestone push. Then `/aid-execute` resumes and asks the open approval
       first; a yes is recorded with `--answer --commit <head>`, and the push question follows.
- **Acceptance criteria:**
  - [ ] `test-landscape.md` names group B and no retired suite.
  - [ ] `INDEX.md` is regenerated and `render-kb-view.sh --check` exits 0; no work id, and the lints pass.

---

## 4. Coverage, and steps that are not tasks

| Stanza item / gate criterion | Task(s) |
|---|---|
| Retired skills: every remaining `aid-create-*`, `aid-update-*`, `aid-document-*`, `aid-test-*`, `aid-prototype-ui`, `aid-remove`, `aid-deprecate`, `aid-migrate`, `aid-experiment`, the ticket and document skills | 318, 319, 320 |
| Retired templates and builder; `generate-profile/SKILL.md` counting from `canonical/skills/` | 321, 322, 323, 326; 325 |
| Tickets: the TICKET step and the connector procedures | 312, 313, 319 |
| Free-form text after `/aid-deploy` and `/aid-monitor` | 314 |
| No impediment file | 315, 323 |
| Format 6 doorway rows with markers and the `Test-AidInstaller.ps1` case; the dashboard maps inside markers | 327, 330; 328, 331 |
| Site generator rewrite; retired flows and pages deleted; pages regenerated | 316, 317; 318-320 regenerate |
| Skill guide: the `<kind>` lines go, SG-02 with no expansion | 318, 319 (follow the folders), 320 |
| Suites of F009 § 8, each in the task that changes its file (Q106) | 313-326 |
| Shared exempt list empty; Feature 009 `skill:` rows gone | 321; 318-320, 333, 334 |
| Re-pointing (every retired name except `aid-config`) | 314, 315, 319, 323, 327, 328, 329 |
| `test-actions.sh` group B | 332 |
| Samples: plain runs of `009-01`, `009-02`, `009-07`; `009-06`, `009-08`, `009-09`, `009-10`, `009-14`, `009-16`; re-runs `001-01`, `001-07`, `003-02`, `008-14`; `009-11`, `009-12` written for the integration run | 333, 334 |
| G0: AC-24 rows in `backlog.md`; KB documents; `INDEX.md`; `kb.html` | 335; 324, 335, 336; 337 |

**Steps that are not tasks** (PLAN.md, How deliveries 010-014 are built). Task-337 carries them in its
"Gate-session steps" block (G13): the run pauses at the MILESTONE approval; the resync session (`delivery-012:
resync`; `aid update` removes the retired files through the manifest; the format-6 doorway rows find no doorway work
in this repository); the gate session (`derive-waves.sh --plan --check`, `gen:reference` and the site `npm test`, then
the stanza's criteria, the samples and G0; then the approval and the push question).

---

## 5. Execution graph

`derive-waves.sh --from-tasks` derives the following from the written task files:

```text
wave 1: task-311
wave 2: task-312, task-314, task-315, task-316
wave 3: task-313, task-317
wave 4: task-318
wave 5: task-319
wave 6: task-320
wave 7: task-321, task-324, task-325
wave 8: task-322
wave 9: task-323, task-326
wave 10: task-327, task-328, task-329
wave 11: task-330, task-331, task-332, task-333, task-335
wave 12: task-334, task-336
wave 13: task-337
```

Step 5 writes the table under `### delivery-012 Execution Graph`, one task per row.

---

## 6. Settled by recommendation (Q136)

| # | Point | Settled as | Basis |
|---|---|---|---|
| S1 | The protocol note and the test step. | As deliveries 010 and 011. | Settled by recommendation (Q136). |
| S2 | The order of the deletions. | Wrappers first (generated, then the ticket skills, then the hand-authored document, test and prototype wrappers), then the engine, the scaffolding and the impediment template; the registry change and the builder before the catalog. Each deletion task's criteria hold at its end: nothing it deletes is still read by a file or suite another task owns. | Settled by recommendation (Q136); G3, G6, G7; stanza wave 3. |
| S3 | The 46 wrapper folders in three tasks. | 318 (30 generated doorways), 319 (the two ticket skills, with their seams), 320 (14 hand-authored wrappers, with the guide's `<kind>` lines and SG-02's expansion). Each removes its own catalog rows and list rows, re-syncs the counts and regenerates the site; the chain orders their shared files. | Settled by recommendation (Q136); one session per task. |
| S4 | When the six family-scaffold suites retire. | With the generated doorways (318), whose deletion breaks them first; the spec retires them, their rules being in the catalog since delivery-011. | F009 § 8, Retired; Q106. |
| S5 | The site generator. | Two tasks before any deletion (316 the skill list and reference pages, 317 the flow graph), after which no site module reads the engine or the catalog; the deletion tasks only regenerate. | Stanza wave 2; G1, G6. |
| S6 | The ticket skills. | The procedures are written first (312), the TICKET step and `ticket` kind next (313), and the skills' retirement carries the ticket seams' re-pointing (319), since its suites read the deleted paths. | F009 § 1, § 8; G6. |
| S7 | Format 6 and its unit cases. | An IMPLEMENT task (327, bash then PowerShell together) and a TEST task (330), as delivery-009's 238 and 244. | One type per task. |
| S8 | The re-pointing. | One sweep (329) after every deletion, owning every hand-written skill from a full listing (G2); the deletion tasks scope their "nowhere" criteria to their own files (G3), except the ticket and impediment names, which their retirement tasks own whole. | G2, G3. |
| S9 | The samples. | 333: the plain-only samples that need the wrappers gone, with the `skill:aid-document` and `skill:aid-prototype` rows; 334: `009-11`, `009-12` (rows waiting for the integration run, delivery-014), `009-14`, `009-16`, the plain runs and the last Feature 009 rows. | Q121; PLAN gate 012; S4 of delivery-011. |
| S10 | The CI lane. | No CONFIGURE task: `test-actions` is already in `SUITES` (task-308); a retired suite leaves `SUITES` in the task that retires it. | G6 widened to `.github/workflows/`. |
| S11 | The KB. | The type registry (324) before the catalog goes; decisions, release notes, quality gates, roadmap and tech debt (335); the architecture set (336); the test landscape with the index and view (337). `aid-config` sites and `## Later` are delivery-013's. | F009 § 8, KB; G0. |
| S12 | KB edits and NEXT's KB check. | Every DOCUMENT task runs on the KB the NEXT calls left, keeps what agrees with the spec, adds what is missing, and corrects only contradictions, naming the entry. | Delivery-010 light review row 10; F007 § 2 step 7; no plan change. |

---

## 7. Flagged for the maintainer

- **G16, the research task's output under the new `/aid-execute`** (delivery-010 light review row 2). Task-311 is
  written in the same form as task-254 and task-288 until this is decided; see the hand-back for the recommendation.
