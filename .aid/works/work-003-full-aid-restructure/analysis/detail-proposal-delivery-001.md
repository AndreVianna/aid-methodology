# Detail proposal -- delivery-001: Ask in plain words

This is `aid-detail` FIRST-RUN Step 1 for **delivery-001 only**. It proposes the delivery's task breakdown
for the maintainer's approval (Q133: delivery by delivery, a short table first). No task folder exists
yet, and none is created until this proposal is approved.

Inputs read: `PLAN.md` (whole, especially § Common Gate (G0), "Testing before the resync (Q131)",
§ Toolchain and Branching and the delivery-001 stanza); `REQUIREMENTS.md` § 9 and § 11 Feature 001;
`known-issues.md`; the work `STATE.yml` `qa` Q104 and Q111-Q133; the KB through `.aid/knowledge/INDEX.md`
(`test-landscape.md`, `authoring-conventions.md`, `architecture.md`, `module-map.md`). Base commit:
`a3b28db4`.

**How anchors read.** "F001 § 5 Migration" is the `##### 5. Migration` subsection of Feature 001's
`#### Technical Specification` in `REQUIREMENTS.md` § 11. "PLAN § X" is a heading or bold lead-in of
`PLAN.md`. A suite marked **scratch** matches the driver's copy-reading pattern (PLAN § Testing before
the resync, The driver, variable `P`); **live** means it does not. Both were measured against this base.

---

## 1. The tasks at a glance

| Task | Title | Type | Stanza wave | Derived wave | Depends on | Executor |
|---|---|---|---|---|---|---|
| task-001 | Delivery-001 site search and reconciled edit list | RESEARCH | 1 | 1 | -- | aid-researcher |
| task-002 | `rules.md` request handling, skill guide and summary bullet | IMPLEMENT | 2 | 2 | task-001 | aid-developer |
| task-003 | Work-state templates with `intent:` and `sources:`, without `ticket_ref` | IMPLEMENT | 2 | 2 | task-001 | aid-developer |
| task-004 | Conversation-suite runner `tests/conversation/run.py` | IMPLEMENT | 2 | 2 | task-001 | aid-developer |
| task-005 | Simulated-user and judge briefs, and the default fixture | IMPLEMENT | 2 | 2 | task-001 | aid-developer |
| task-006 | `/aid-orchestrate` skill and its five references | IMPLEMENT | 3 | 3 | task-002, task-003 | aid-developer |
| task-007 | Work sources in the skills, and the ticket `attachment` part | IMPLEMENT | 3 | 3 | task-003 | aid-developer |
| task-008 | `aid-orchestrator` agent retired and `/aid-monitor` re-pointed | IMPLEMENT | 3 | 4 | task-006 | aid-developer |
| task-009 | `/aid-triage` retired, with its site roster and tests | IMPLEMENT | 3 | 5 | task-006, task-007, task-008 | aid-developer |
| task-010 | What/when skill descriptions and the doorway builder template | IMPLEMENT | 4 | 6 | task-009 | aid-developer |
| task-011 | User documents and site pages without the triage router or orchestrator agent | DOCUMENT | 4 | 6 | task-008, task-009 | aid-tech-writer |
| task-012 | KB decisions, backlog and record documents for plain requests | DOCUMENT | 4 | 6 | task-007, task-009 | aid-tech-writer |
| task-013 | KB architecture and navigation documents for plain requests | DOCUMENT | 4 | 6 | task-006, task-009 | aid-tech-writer |
| task-014 | Skill-guide static suite `test-skill-guide.sh` (SG-01 to SG-06) | TEST | 5 | 7 | task-010 | aid-developer |
| task-015 | `test-skill-guide` in the feature-branch CI lane | CONFIGURE | 5 | 8 | task-014 | aid-developer |
| task-016 | Feature 001 samples `001-01` to `001-08`: reading and matching a request | TEST | 5 | 7 | task-004, task-005, task-010 | aid-developer |
| task-017 | Feature 001 samples `001-09` to `001-16`: phases, sources and closing | TEST | 5 | 7 | task-004, task-005, task-010 | aid-developer |
| task-018 | KB test landscape for the two new suites, and the regenerated index | DOCUMENT | 4 (moved, D2) | 9 | task-012, task-013, task-015, task-016, task-017 | aid-tech-writer |

After task-018 comes the delivery's resync step, which is not a task (§ 6).

---

## 2. Rules every task follows

- **One type per task.** No task mixes types.
- **Same task, same suites (Q106).** A task that rewrites, moves or deletes a file also updates every
  suite that asserts text in it. It is not `Done` while such a suite fails. "Suites" includes
  `site/scripts/__tests__/` and the dashboard tests. Many of them read real `canonical/skills/` bodies.
- **Coverage ledgers.** A task that removes an assertion adds its row to
  `tests/coverage-accepted-removals.tsv`. A task that renames one adds its row to
  `tests/coverage-rehome-allowlist.tsv`. The baselines themselves are re-recorded at the gate (D11).
- **Site regeneration in the same task.** The committed generated site files are read from `canonical/`
  by `site/scripts/gen-skills.mjs` and `gen-reference.mjs`. They are the skill pages, `skills/index.md`,
  `src/data/skill-flows/*.flow.json`, `reference/skills.md` and `scripts/.skills-manifest.json`.
  - Every task that changes `canonical/skills/**` or `shortcut-catalog.yml` runs
    `(cd site && npm run gen:skills && npm run gen:reference)` and commits the output.
  - A task that changes one of the `docs/` files `sync-docs.mjs` mirrors runs `(cd site && npm run sync:docs)`.
  - Generated files are never edited by hand.
  - Two tasks in one wave that both regenerate cannot disagree: the later run reproduces the earlier
    output plus its own.
- **No generator in the live tree.** No task runs `run_generator.py` there. The resync is a delivery step
  (PLAN § Toolchain and Branching, The resync rule, rule 1). The doorway builder
  `build-shortcut-skills.py` is not the generator, so task-010 runs it.
- **The search findings complete each scope.** Each later task's Scope ends with "plus every site
  `research/delivery-001-sites.md` assigns to this task". Task-001's search therefore reaches every task
  without rewriting any task file.
- **Tracking (Q125, Q127).** The main conversation writes `In Progress` and `In Review` as two state-only
  commits per task. It writes the terminal state and grade in the task's own commit. The file holding the
  state is `deliveries/delivery-001/tasks/task-NNN/STATE.yml` (PLAN § Common Gate (G0), Which file holds
  the task's state).

---

## 3. The standard test step

Every task file carries this step verbatim as the last Scope bullet. It is PLAN § "Testing before the
resync" applied to one task. `BASE` is the task's `task-NNN: In Progress` commit.

1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
   changed `.py`, and `node --check` on each changed `.mjs`.
2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
   - `COPY` is the members of `SEL` whose text matches the driver's `P`.
   - `LIVE` is `SEL` minus `COPY`.
   - A task whose changes all lie under `.aid/works/` selects nothing. `rules.md` § Tracking discipline
     forbids any test from depending on a work folder.
3. **Scratch half** (when `COPY` is not empty).
   - Make the copy exactly as PLAN § "How the copy is made" says, with `S=.aid/.temp/scratch/task-NNN`.
     That includes the copy's own `run_generator.py`, run from inside it, then the `resync` commit.
   - Delete from `"$S"/tests/canonical/` every `test-*.sh` not in `COPY`.
   - Run `(cd "$S" && HOME="$(mktemp -d)" bash tests/run-all.sh)` and record its failures.
   - Run `rm -rf "$S"` before step 4.
   - If the copy's generator fails, that failure is the result, and `COPY` is reported as not run.
4. **Live half.**
   - When `LIVE` is every suite outside `COPY` (the usual case, D12), run
     `HOME="$(mktemp -d)" bash tests/run-all.sh` and drop the `COPY` suites' results by name.
   - Otherwise, run each `LIVE` suite with `HOME="$(mktemp -d)" bash tests/canonical/<suite>`.
5. **Outside `run-all.sh`.**
   - Run `(cd site && npm test)` when the task changes `canonical/skills/`, `shortcut-catalog.yml`,
     `docs/` or `site/`. Run `npm ci` there first if `site/node_modules` is absent, which it is in this
     worktree today.
   - Run `python3 -m pytest <file>` for each dashboard test file the task changes.
6. **Result and report.** The tests pass when steps 1 and 3 to 5 report no failure.
   - The executor reports each suite with where it ran, its result and its run count.
   - Ceiling (T5): one full step-2-to-5 run per test round. Between rounds, only the failing group is
     re-run (T6).
   - The same failure after three fix rounds goes to the maintainer (PLAN § How deliveries 001-009 are
     built, step 2.6).

---

## 4. Tasks

Every `Source` line reads `feature-001-plain-language-requests -> delivery-001 -> AC-...`. Each task's
criteria include the type defaults from `task-decomposition.md` § Type-specific default criteria, and
"all REQUIREMENTS § 6 quality gates hold" (NFR-N, NFR-T, NFR-Q). They are not repeated below.

### task-001: Delivery-001 site search and reconciled edit list [RESEARCH]

- **Waves:** stanza 1, derived 1. **Depends on:** --.
- **Source:** AC-6, AC-21, AC-23, AC-29. It finds the sites these criteria's edits must reach.
- **Scope:**
  - Creates `.aid/works/work-003-full-aid-restructure/research/delivery-001-sites.md`. It touches nothing else.
  - Re-runs the spec's stated searches at the task's base commit. Path set: `canonical/`, `site/`,
    `docs/`, `examples/`, `README.md`, `.aid/knowledge/`, `.aid/design/`, `tests/`, `dashboard/`, `bin/`,
    `lib/` and `.claude/skills/generate-profile/`.
    - **S1** triage: `aid-triage`, `/aid-triage`, "triage router" (F001 § 5, Triage sites, and its final
      search).
    - **S2** orchestrator: `aid-orchestrator`, and "orchestrator" as the agent's name (F001 § 5,
      Orchestrator sites).
    - **S3** `ticket_ref` (F001 § 5, `ticket_ref` sites).
    - **S4** `skill-routing.md`.
    - **S5** suites asserting the rules text: the summary markers, the summary wording and the rules
      headings (F001 § 5, the "Suites that assert the rules text" table).
    - **S6** the Q106 map. For every file on the delivery's edit list, it finds the suites that read the
      file by path or assert its text, including `site/scripts/__tests__/` and the dashboard tests.
    - **S7** count-derived checks. These are suites deriving counts from `canonical/skills/` or
      `canonical/agents/` (`test-doc-counts.sh`, `site/scripts/__tests__/skill-counts.test.mjs`), with the
      phrases they assert.
    - **S8** description checks. These are suites and site tests that read a `SKILL.md` `description:`,
      and the builder's `description = (` template.
    - **S9** the SG-04 exempt list: every skill whose deletion or rename a later feature's
      `##### 1. Files and layout` states (D4).
    - **S10** site page classes. Each site hit is classed as generated (`gen-skills`, `gen-reference`),
      synced (`sync-docs`) or hand-written.
  - Each hit gets exactly one owner, which is one of:
    - a task of this proposal;
    - "installed copy (resync)", for `.claude/skills/aid-*`, `.agents/`, `.aid/runtime/`, `profiles/`
      and `.aid/.aid-manifest.json`;
    - "history, left as is", for `release-tracking.md`, `coverage-accepted-removals.tsv` and `kb.html`
      (F001 § 5, Left as they are).
- **Suites updated in the same task:** none. It changes only the work folder.
- **Acceptance criteria:**
  - [ ] Each of S1-S10 shows its exact command. Re-running each command at the base commit named in the
    file reproduces its hit list line for line.
  - [ ] Every hit row has exactly one owner from the classes above. The count of rows with an empty
    owner cell is 0.
  - [ ] A delta section lists every hit the spec's F001 § 5 lists omit, and every spec-listed path with
    no hit, each with its owner. It also lists any suite assigned to two tasks that do not depend on each
    other, with the order to run them.
  - [ ] The S9 exempt list names, per row, the skill and the anchor of the later feature that deletes or
    renames it. No skill that keeps its name through v4.0.0 appears in it.
  - [ ] RESEARCH defaults overridden: the spec fixes the searches, so there are no alternatives to compare.
    The commands are the cited sources.

### task-002: `rules.md` request handling, skill guide and summary bullet [IMPLEMENT]

- **Waves:** stanza 2, derived 2. **Depends on:** task-001.
- **Source:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-6; KI-001.
- **Scope:** edits `canonical/aid/rules.md` (F001 § 1 and § 3, Components):
  - `## Handling a request` replaces `## Workflow`. It starts from the spec's draft and stays at most 20
    lines by the SG-01 counting rule.
  - A new `## Skill guide`:
    - one line per skill, at most 100 characters, in the order phase, KB, supporting, setup;
    - `<kind>` family lines that expand against `shortcut-catalog.yml`;
    - the set it names is `canonical/skills/` as the delivery leaves it: today's set, without
      `aid-triage`, with `aid-orchestrate`.
  - The summary gains the spec's bullet and goes from 7 to 8 bullets.
  - KI-001 fixed in § Tracking discipline: the work state file is `STATE.yml`, and the "FULL or the
    LITE path" wording goes.
  - No tool folder, no `canonical/` path and no extra `<!-- AID` comment (`test-shared-layout-sources.sh`).
- **Suites updated in the same task:**
  - `test-shared-layout-sources.sh` (scratch): "rules summary block carries the seven bullets" -> eight;
  - `test-install-core-primitives.sh` (scratch): "summary block: seven bullets (one wraps ...)" -> the new
    physical line count;
  - `test-aid-cli-parity.sh` FIX-D8 (scratch): `## Workflow` -> `## Handling a request`;
  - any other suite task-001's S5 assigns.
- **Acceptance criteria:**
  - [ ] `awk '/^## /{p=($0=="## Handling a request")} p' canonical/aid/rules.md | awk 'NF{n=NR} END{print n}'`
    prints at most 20, and the section holds each rule of the spec's draft: match by meaning, a project
    question starts no work, one/several/none, a typed command wins, check the reading, `/aid-orchestrate`,
    show the reading, which phases run, re-route, KB conflicts, one topic at a time (AC-1 to AC-5, AC-6).
  - [ ] The summary block holds 8 bullets:
    `sed -n '/^<!-- AID:SUMMARY:BEGIN -->$/,/^<!-- AID:SUMMARY:END -->$/p' canonical/aid/rules.md | grep -c '^- '`
    prints 8. The new bullet carries the spec's wording (AC-1, AC-4).
  - [ ] Guide lines over 100 characters: 0 (the SG-03 rule). The guide's names, with `<kind>` expanded
    against the catalog, equal `canonical/skills/` minus `aid-triage` plus `aid-orchestrate`, both ways (the
    SG-02 rule, run by hand until task-014) (AC-6).
  - [ ] § Tracking discipline names `.aid/works/work-NNN-*/STATE.yml`, and `grep -c 'LITE path'
    canonical/aid/rules.md` prints 0 (KI-001).
  - [ ] The three suites above pass in the scratch copy, and the rest of the selection passes (§ 3).

### task-003: Work-state templates with `intent:` and `sources:`, without `ticket_ref` [IMPLEMENT]

- **Waves:** stanza 2, derived 2. **Depends on:** task-001.
- **Source:** AC-29.
- **Scope:**
  - `canonical/aid/templates/work-state-template.yml`:
    - adds `intent:` (`request`, `reading`, `reason`, `depth`, `phases` as a block list, `changes: []`)
      and `sources: []`, with comments in the template's `[W]` style;
    - adds `write_backs: []`, if D7 is accepted;
    - removes `ticket_ref` and its note.
  - `delivery-state-template.yml` and `task-state-template.yml`: remove `ticket_ref` and its notes.
  - `requirements/requirements-template.md`: removes the feature `**Ticket:**` line and its comment.
- **Suites updated in the same task:**
  - `test-work-state-template.sh` (scratch);
  - `test-ticket-retirement-structural.sh` T087-T089 (scratch);
  - the template assertions of `test-connector-consumption-linkage.sh` (live);
  - `dashboard/server/tests/test_task033_execution_control_round_trips.py`;
  - their coverage-ledger rows, and any suite S3 or S6 assigns.
- **Acceptance criteria:**
  - [ ] `git grep -n ticket_ref` over the four edited templates finds nothing, and `git grep -n '\*\*Ticket:\*\*'
    canonical/aid/templates/requirements/requirements-template.md` finds nothing. This is the template
    clause of the gate's AC-29 criterion. task-007 completes it.
  - [ ] `intent:` holds the six keys in block style. `grep -nE '^[^#]*:[[:space:]]*[[{][^]}]'
    canonical/aid/templates/work-state-template.yml` finds nothing (no flow collection but `[]`/`{}`
    outside comments), and no key sits deeper than three levels (KI-002).
  - [ ] Both dashboard readers, `dashboard/reader/state_schema.py` and `dashboard/server/reader.mjs`,
    parse the edited template with no warning. `test-dashboard-reader.sh` and `test-dashboard-parity.sh`
    pass live.
  - [ ] `test-work-state-template.sh` and `test-ticket-retirement-structural.sh` pass in the scratch copy.
    The linkage suite and `test_task033` pass live, and every removed or renamed assertion has its ledger
    row.

### task-004: Conversation-suite runner `tests/conversation/run.py` [IMPLEMENT]

- **Waves:** stanza 2, derived 2. **Depends on:** task-001.
- **Source:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-7, AC-14, AC-21, AC-29 (the harness that verifies them;
  NFR-T).
- **Scope:** creates `tests/conversation/run.py` (Python 3, standard library only), per F001 § 6,
  Conversation suite.
  - **Arguments:** `--feature NNN [--sample ID] [--hosts ...] [--runs 3]`.
  - **Samples:** reads `samples/feature-NNN/<id>.md`: frontmatter `id`, `covers`, `fixture`, and the five
    sections.
  - **`## Checks` grammar:** written in `run.py`'s header. It covers what the 16 Feature 001 samples need:
    a file exists or is absent, a file contains a text, no new folder under a path, and no push.
  - **Fixture:** a fresh throwaway git project copied from `tests/conversation/fixtures/<fixture>/`.
    - AID is installed in it from a bundle staged by `tests/lib/bundle.sh`.
    - A sample's `bin/` goes first on `PATH`.
    - Each run gets a throwaway `HOME`.
  - **Claude Code driver:** `claude -p` with `--output-format stream-json` and `--resume`, plus the
    `--input-format stream-json` fallback.
  - **Other hosts:** an adapter with the three steps start, send, read. A host without one is skipped
    with a notice.
  - **Flags:** the spec's flags for the agent, the simulated user and the judge.
  - **Limits:** a 12-turn cap and a 10-minute turn timeout.
  - **Capture:** `transcript.jsonl`, `transcript.md`, `files.diff` (with the exclusions), `checks.txt` and
    the ledger, in the run folder and in the fixture's `.aid/.temp/review-pending/`.
  - **Pass rule:** a Pending row fails the run, and a sample passes only on 3 of 3.
  - **Exits:** 0, 1 or 2.
  - It confirms the built-in tool names `Skill` and `Task` against `claude --help`, and records the
    result in a comment.
- **Suites updated in the same task:** none exist. The stub checks below run from the task's scratch area
  and are not committed (D10).
- **Acceptance criteria:**
  - [ ] `python3 tests/conversation/run.py --feature 001 --sample no-such-sample` exits 2, and so does a
    call without `--feature`. Every module `run.py` imports is in `sys.stdlib_module_names`.
  - [ ] With a stub `claude` first on `PATH` that logs its argv and answers in stream-json, one
    `--runs 1` run writes the five capture files into
    `.aid/.temp/conversation-tests/<run-id>/<sample>/run-1/`. The log shows these flags:
    - **agent turns:** `--permission-mode acceptEdits`,
      `--tools Read,Glob,Grep,Edit,Write,Bash,Skill,Task`, the same `--allowedTools`,
      `--strict-mcp-config`, `--setting-sources project`, no `--add-dir`, and `--resume` from turn 2 on;
    - **simulated user and judge:** `--tools ""`, `--safe-mode`, `--strict-mcp-config` and
      `--system-prompt`.
  - [ ] A stub turn that writes into the fixture's `.git/`, `HOME/.claude/`, `HOME/.claude.json` and a
    credential file leaves none of them in `files.diff`. A binary file appears as path and size only.
  - [ ] A stub judge ledger with one Pending row fails its run. A sample with one failed run out of 3
    exits 1. A stub that never sends `<<END>>` fails at the 12-turn cap.

### task-005: Simulated-user and judge briefs, and the default fixture [IMPLEMENT]

- **Waves:** stanza 2, derived 2. **Depends on:** task-001.
- **Source:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-7, AC-14, AC-21, AC-29 (NFR-T).
- **Scope:** creates:
  - `tests/conversation/simulated-user.md`;
  - `tests/conversation/judge.md`, which `run.py` puts after the installed `aid-reviewer` agent body;
  - `tests/conversation/fixtures/default/`. This is a small git-ready project with code and a seeded
    `.aid/knowledge/` holding at least `INDEX.md`, `capability-inventory.md`, `module-map.md` and
    `architecture.md`, the read list of `check-intent.md` (F001 § 2, step 4). It has no AID install,
    because `run.py` installs AID per run.
- **Suites updated in the same task:** none.
- **Acceptance criteria:**
  - [ ] `simulated-user.md` states, each as its own greppable line, four rules: answer only from the
    sheet; "I don't know" otherwise; never volunteer a skill name; reply `<<END>>` when the sheet has
    nothing left or the agent has finished. `grep -c '/aid-' tests/conversation/simulated-user.md` prints 0.
  - [ ] `judge.md` names its four inputs: `transcript.md`, `files.diff`, `checks.txt` and the expected
    outcome with `## Must not`. It requires output that is only the 7-column ledger with the header
    `# | Severity | Status | Doc | Line | Description | Evidence`, and says that an unmet expectation is a
    Pending row.
  - [ ] The default fixture's KB documents carry the frontmatter fields `kb-category`, `source`,
    `objective`, `summary` and `sources`. The fixture holds no credential, no `.git/` and no AID file.

### task-006: `/aid-orchestrate` skill and its five references [IMPLEMENT]

- **Waves:** stanza 3, derived 3. **Depends on:** task-002 (the rules sections it serves), task-003 (the
  `intent:` and `sources:` shapes it records).
- **Source:** AC-1, AC-2, AC-3, AC-4, AC-7, AC-14, AC-29.
- **Scope:**
  - Creates `canonical/skills/aid-orchestrate/SKILL.md`: at most 80 lines, runs in the main conversation,
    no sub-agent. Its description is verbatim from F001 § 3.
  - Creates `references/` (F001 § 2, § 3, § 4), each reference at most 120 lines:
    - `start-or-resume.md`: cites `.aid/runtime/scripts/works/enumerate-works.sh` and
      `.aid/runtime/templates/work-initiation-gate.md` without restating them; reads the resume point;
      records `intent:`.
    - `check-intent.md`: the KB-and-code check, triage's question shortcut and work-type heuristic moved in
      from `canonical/skills/aid-triage/SKILL.md`, and the kind hook on `shortcut-catalog.yml` `intent:`.
    - `size-and-route.md`: the routing rule, the phase table, the depth table, triage's scope judgement and
      the close minimum (`writeback-state.sh --pipeline --field Lifecycle --value Completed`) until
      delivery-010.
    - `external-sources.md`: pull in, apply, write back through `/aid-update-ticket` `attachment`, tool
      limits, no credential.
    - `feedback-routing.md`: the table moved in from `canonical/agents/aid-orchestrator/AGENT.md`.
  - Site regeneration: the new page, the flow, the index and the manifest. `aid-orchestrate` joins the
    curated roster in the Support group (D6).
  - The skill-count phrases `test-doc-counts.sh` asserts in `README.md` and `docs/` are re-synced to the
    derived count, then `sync:docs` runs (D5).
- **Suites updated in the same task:**
  - `test-deploy-monitor-repurpose.sh` (scratch): its standalone, not-a-catalog-row list gains
    `aid-orchestrate`;
  - `test-doc-counts.sh` (live);
  - the site tests that pin the curated roster or the skill counts;
  - any suite S6 or S7 assigns.
- **Acceptance criteria:**
  - [ ] `wc -l` gives at most 80 for `SKILL.md` and at most 120 for each reference. The five reference
    names match F001 § 3. `name:` equals the folder, and `description:` equals the spec's text.
  - [ ] `check-intent.md` names the four KB reads and the classify-by-observable-effect rule.
    `size-and-route.md` holds the routing-rule sentence, the phase table, the depth table and the
    close-minimum command (AC-7, AC-14). `external-sources.md` holds the four procedures and the
    `sources:` / `write_backs:` entry shapes of F001 § 4 (AC-29). `feedback-routing.md` holds the four
    routing rows.
  - [ ] Every `.aid/runtime/...` pointer in the skill resolves to a `canonical/aid/` file (SR-01), and
    no file under `canonical/skills/aid-orchestrate/` names an agent to dispatch.
  - [ ] `test-deploy-monitor-repurpose.sh` passes in the scratch copy, `test-doc-counts.sh` passes live
    and the site `npm test` passes. The rest of the selection passes (§ 3).

### task-007: Work sources in the skills, and the ticket `attachment` part [IMPLEMENT]

- **Waves:** stanza 3, derived 3. **Depends on:** task-003.
- **Source:** AC-29.
- **Scope:**
  - `canonical/aid/templates/connectors/consumption-protocol.md`: § Multi-level `ticket_ref` linkage is
    rewritten for the one work-level `sources:` list.
  - The other `ticket_ref` sites write or read a `sources:` entry instead. They are:
    - `canonical/aid/templates/shortcut-engine.md`;
    - `aid-specify` `references/state-initialize.md` Step 3b;
    - `aid-plan` `references/first-run-loop.md`;
    - `aid-describe` `references/state-first-run.md`.
  - `canonical/skills/aid-update-ticket/SKILL.md`:
    - the closed enum becomes `description | comment | status | attachment`;
    - the usage line, the `argument-hint` and `description:` follow it;
    - `attachment` gets its own LOAD-CONTEXT, preview and confirm steps for the files the user picks, and
      the tool-limit stop (F001 § 4).
  - Site regeneration: the flows that carry `ticket_ref`, and the `aid-update-ticket` page.
- **Suites updated in the same task:**
  - `test-connector-consumption-linkage.sh` (live);
  - `test-ticket-retirement-structural.sh` T073, T091 and the skill-site assertions (scratch);
  - `test-ticket-skills-structural.sh`, the part enum (live);
  - their coverage-ledger rows, and any suite S3 or S6 assigns.
- **Acceptance criteria:**
  - [ ] `git grep -n ticket_ref -- canonical/` finds nothing. This completes the gate's AC-29 template
    criterion with task-003. `git grep -c ticket_ref -- site/src/data/skill-flows/` prints nothing after
    regeneration.
  - [ ] `aid-update-ticket`'s enum reads `description | comment | status | attachment` everywhere it
    appears. The `attachment` path names the picked files, previews, confirms, and on a tool limit stops,
    tells the user and offers options with a recommendation. It never picks a workaround (AC-29).
  - [ ] The rewritten consumption-protocol section states the `sources:` entry fields `ref`, `kind`,
    `added`, `phase` and `effect`, and the top-level `write_backs:` entry fields `at`, `source`, `part`
    and `files`, as F001 § 4 does.
  - [ ] The three suites above pass where § 3 puts them, and the site `npm test` passes.

### task-008: `aid-orchestrator` agent retired and `/aid-monitor` re-pointed [IMPLEMENT]

- **Waves:** stanza 3, derived 4. **Depends on:** task-006. Its `feedback-routing.md` takes the agent's
  table before this task deletes the agent, and both tasks edit `test-deploy-monitor-repurpose.sh`.
- **Source:** AC-6 (no orchestrator sub-agent), AC-23.
- **Scope:**
  - Deletes `canonical/agents/aid-orchestrator/`.
  - Re-points `canonical/aid/templates/agent-dispatch-tiering.md` § Per-agent defaults and
    `canonical/aid/templates/self-review-protocol.md`.
  - `canonical/skills/aid-monitor/SKILL.md`: the Default executor line, the ROUTE dispatch row and the
    routing targets. ROUTE now runs inline, and no target is `/aid-triage`.
  - `references/state-route.md`: a bug goes back as a fix request, and a change request as a new-work
    request, both in plain words through `rules.md` § Handling a request.
  - Deletes `.aid/design/skill-routing.md`, and removes any mention of it in `.aid/design/README.md`.
  - Agent-count phrases are re-synced (D5). Site regeneration covers the `aid-monitor` page and flow.
  - `tests/windows/Test-AidInstaller.ps1` stays as it is: it uses `aid-orchestrator.md` only as a legacy
    fixture name.
- **Suites updated in the same task:**
  - `test-deploy-monitor-repurpose.sh` (scratch): DMR01b, DMR02b, DMR03b and the ROUTE-row assertion;
  - `test-doc-counts.sh` (live);
  - the site tests that read the `aid-monitor` body;
  - any suite S2 or S6 assigns.
- **Acceptance criteria:**
  - [ ] `test -e canonical/agents/aid-orchestrator` fails, `git grep -n aid-orchestrator -- canonical/
    .aid/design/` finds nothing, and `.aid/design/skill-routing.md` is absent. `git diff "$BASE" --
    tests/windows/Test-AidInstaller.ps1` is empty (AC-23).
  - [ ] `aid-monitor`'s ROUTE row names no agent, and `git grep -n -E 'aid-triage|aid-orchestrator' --
    canonical/skills/aid-monitor/` finds nothing. `state-route.md` hands back each finding class in plain
    words (AC-23).
  - [ ] `canonical/agents/aid-developer/` and `canonical/agents/aid-tech-writer/` exist (the SG-05
    clause), and `test-doc-counts.sh` passes live with the new agent count.
  - [ ] `test-deploy-monitor-repurpose.sh` passes in the scratch copy, and the site `npm test` passes.

### task-009: `/aid-triage` retired, with its site roster and tests [IMPLEMENT]

- **Waves:** stanza 3, derived 5. **Depends on:**
  - task-006: the heuristics have moved;
  - task-008: `aid-monitor` no longer names it, and both edit `test-deploy-monitor-repurpose.sh`;
  - task-007: both edit `aid-describe/references/state-first-run.md`.
- **Source:** AC-6 (no front-door skill; the guide covers every skill).
- **Scope:**
  - Deletes `canonical/skills/aid-triage/`.
  - Removes the triage mentions in `shortcut-catalog.yml`.
  - Re-points `aid-describe` `SKILL.md`, `references/elicitation-engine.md` and
    `references/state-first-run.md`.
  - Updates `.claude/skills/generate-profile/SKILL.md`, whose curated count includes the triage router.
  - Updates the site scripts: `site/scripts/skills/` (roster, groups, counts, index) and `gen-reference.mjs`.
  - Site regeneration deletes `skills/aid-triage.md` and `aid-triage.flow.json`, and refreshes the
    `aid-describe` and `aid-monitor` flows and the manifest.
  - Deletes `tests/canonical/test-triage-routing.sh`.
  - Skill-count phrases are re-synced (D5).
- **Suites updated in the same task:**
  - the site tests under `site/scripts/__tests__/` that name `aid-triage` at this base (`flow-classify`,
    `flow-extract-dispatch`, `flow-graph`, `gen-reference`, `gen-skills-index`, `skill-counts`,
    `skills-groups`, `skills-render-index`). Several of them read the real `aid-triage` body, so they
    change in this task. After it, `aid-orchestrate` takes triage's first place in Support (D6);
  - `test-cutover-no-dangling.sh` (scratch);
  - `test-deploy-monitor-repurpose.sh` (scratch), which drops `aid-triage` from its standalone list;
  - `test-doc-counts.sh` (live);
  - the accepted-removal rows for every assertion `test-triage-routing.sh` held;
  - any suite S1 or S6 assigns.
- **Acceptance criteria:**
  - [ ] `test -e canonical/skills/aid-triage` fails. `git grep -n -E 'aid-triage|triage router' --
    canonical/ .claude/skills/generate-profile/ site/scripts/ tests/canonical/` finds no line outside the
    ones task-001 classes as history (AC-6).
  - [ ] `test-triage-routing.sh` is gone. Every one of its assertion ids in `tests/coverage-baseline.tsv`
    has a row in `tests/coverage-accepted-removals.tsv`.
  - [ ] `site/src/content/docs/skills/aid-triage.md` and `site/src/data/skill-flows/aid-triage.flow.json`
    are absent, and the site `npm test` passes.
  - [ ] `test-cutover-no-dangling.sh` and `test-deploy-monitor-repurpose.sh` pass in the scratch copy, and
    `test-doc-counts.sh` passes live.

### task-010: What/when skill descriptions and the doorway builder template [IMPLEMENT]

- **Waves:** stanza 4, derived 6. **Depends on:** task-009. It needs the final skill set and catalog, and
  through task-009 also task-006 and task-008, which edit `aid-orchestrate` and `aid-monitor`.
- **Source:** AC-21; AC-1 (descriptions are what the agent matches).
- **Scope:**
  - Rewrites `description:` in every hand-authored `canonical/skills/*/SKILL.md` that is not on the S9
    exempt list. Each one has a what-sentence, then one sentence starting "Use when", in line with its
    guide line in `rules.md` (F001 § 3, Skill descriptions).
  - `.claude/skills/generate-profile/scripts/build-shortcut-skills.py`: the `description = (` template
    becomes the catalog row's `intent:` followed by one "Use when" sentence. The builder then regenerates
    the doorways, and no `GENERATED` file is edited by hand.
  - Site regeneration.
- **Suites updated in the same task:**
  - `test-shortcut-builder-invariants.sh` SBI05 (scratch);
  - the suites and site tests S8 lists that assert description text;
  - their coverage-ledger rows.
- **Acceptance criteria:**
  - [ ] A check run from the task's scratch area joins each non-exempt folded `description:` and tests
    that its first sentence precedes a second sentence starting "Use when". It prints zero violators.
    This is the SG-04 rule, ahead of its suite (AC-21).
  - [ ] `python3 .claude/skills/generate-profile/scripts/build-shortcut-skills.py --check` exits 0, and
    each doorway's `description:` equals its row's `intent:` plus one "Use when" sentence.
  - [ ] `test-shortcut-builder-invariants.sh` passes in the scratch copy, and the site `npm test` passes.

### task-011: User documents and site pages without the triage router or orchestrator agent [DOCUMENT]

- **Waves:** stanza 4, derived 6. **Depends on:** task-008, task-009. Both names must be gone first.
- **Source:** AC-6, AC-23.
- **Scope:** small targeted edits, not a rewrite. AC-45's pass is delivery-014's.
  - Edited files:
    - `README.md`;
    - `docs/aid-methodology.md`, `docs/diagram-content-reference.md`, `docs/faq.md`, `docs/glossary.md`
      and `docs/repository-structure.md`;
    - `examples/brownfield-full-path/README.md`;
    - every hand-written page under `site/src/content/docs/` that S10 lists. Synced pages are refreshed
      with `sync:docs`; generated pages are not edited.
  - "Triage" becomes "say what you want; the skill guide routes it". The orchestrator agent becomes the
    agent in your tool, with `/aid-orchestrate`.
- **Suites updated in the same task:** `test-doc-counts.sh` (live) if a counted phrase is touched; any
  suite S6 assigns.
- **Acceptance criteria:**
  - [ ] `git grep -n -E 'aid-triage|triage router|aid-orchestrator' -- README.md docs/ examples/
    site/src/content/` finds no line outside task-001's history class (AC-6, AC-23).
  - [ ] `(cd site && npm run sync:docs)` leaves no diff, and the site `npm test` passes.
  - [ ] Each edited statement matches `canonical/` as task-009 leaves it, and `test-doc-counts.sh`
    passes live.

### task-012: KB decisions, backlog and record documents for plain requests [DOCUMENT]

- **Waves:** stanza 4, derived 6. **Depends on:** task-007, task-009.
- **Source:** AC-23, AC-24, AC-29.
- **Scope:** edits six documents under `.aid/knowledge/` (F001 § 5, KB and Release notes):
  - `decisions.md` gets the new decision "the host agent orchestrates":
    - it supersedes D21 and D25's change-request route; both are marked Superseded in the summary table
      and in their sections;
    - it amends D14 (its pointer to D21) and D15 (the agent count).
  - `backlog.md` § Next Release: the old -> new rows for `/aid-triage` and the `aid-orchestrator` agent.
  - `tech-debt.md`: row W1-6.
  - `infrastructure.md`: its `ticket_ref` sentence.
  - `artifact-schemas.md`: the Pipeline State, Delivery Lifecycle and Task State rows lose `ticket_ref`;
    `intent:`, `sources:` and `write_backs:` are added.
  - `integration-map.md`.
  - No work id anywhere. The `kb-doc` criteria apply.
- **Suites updated in the same task:** any suite S6 lists that reads these documents.
- **Acceptance criteria:**
  - [ ] `backlog.md` § Next Release has the `/aid-triage` and `aid-orchestrator` rows with F001 § 5's
    New text (AC-24, the G0 item).
  - [ ] D21 and D25 read Superseded in both places, and D14 and D15 are amended. `git grep -n ticket_ref
    -- .aid/knowledge/artifact-schemas.md .aid/knowledge/infrastructure.md` finds nothing (AC-29).
  - [ ] `git grep -n -E 'work-[0-9]{3}'` over the six documents finds nothing.
    `bash .aid/runtime/scripts/kb/kb-citation-lint.sh` and `lint-frontmatter.sh` pass on them.

### task-013: KB architecture and navigation documents for plain requests [DOCUMENT]

- **Waves:** stanza 4, derived 6. **Depends on:** task-006, task-009.
- **Source:** AC-1, AC-6, AC-23.
- **Scope:** edits six documents under `.aid/knowledge/`:
  - `architecture.md`: the orchestrator retired; the host agent and `/aid-orchestrate`;
  - `pipeline-contracts.md`: the entry doors, and the L10 feedback-loop target;
  - `capability-inventory.md`, `domain-glossary.md`, `module-map.md` (the `aid-orchestrate` module) and
    `project-structure.md` (`tests/conversation/`).
  - It does not touch `INDEX.md`, which task-018 regenerates last.
- **Suites updated in the same task:** `test-deploy-monitor-repurpose.sh` DMR05c (scratch), which reads
  `pipeline-contracts.md`; any suite S6 lists.
- **Acceptance criteria:**
  - [ ] `git grep -n -E 'aid-triage|triage router|aid-orchestrator'` over the six documents finds no line
    outside task-001's history class (AC-6, AC-23).
  - [ ] `pipeline-contracts.md` routes a plain request through `rules.md` § Handling a request to
    `/aid-orchestrate` (AC-1). DMR05c is re-pointed, and the suite passes in the scratch copy.
  - [ ] No work id, and the citation and frontmatter lints pass on the six documents.

### task-014: Skill-guide static suite `test-skill-guide.sh` (SG-01 to SG-06) [TEST]

- **Waves:** stanza 5, derived 7. **Depends on:** task-010. Every SG group needs the finished guide,
  skill set and descriptions.
- **Source:** AC-6, AC-21, AC-23.
- **Scope:** creates `tests/canonical/test-skill-guide.sh` (F001 § 6, Static check):
  - a bash harness on `tests/lib/assert.sh`, with `# COVERS:` lines for `canonical/aid/rules.md`,
    `canonical/skills/` and `canonical/agents/`;
  - groups SG-01 to SG-06, with a group filter (T6);
  - the SG-04 exempt list from task-001's S9. A row naming a missing skill fails, and
    `AID_RELEASE_CHECK=1` fails while the list is not empty;
  - SG-06 stages one bundle through `tests/lib/bundle.sh` and installs it for each of the five tools.
  - It reads `profiles/` through the bundle and names `.claude/skills/` and `.agents/skills/`, so it is
    copy-reading: it runs in the scratch copy.
- **Suites updated in the same task:** none.
- **Acceptance criteria:**
  - [ ] In the scratch copy, `bash tests/canonical/test-skill-guide.sh` exits 0 with a PASS for each of
    SG-01 to SG-06.
  - [ ] Each mutation fails its group and is restored afterwards:
    - a 21st line in § Handling a request (SG-01);
    - a guide line removed, or a stray skill folder added (SG-02);
    - a 101-character line (SG-03);
    - a description without "Use when", an exempt row naming a missing skill, or
      `AID_RELEASE_CHECK=1` with a non-empty list (SG-04);
    - `canonical/skills/aid/` or `canonical/agents/aid-orchestrator/` created, or
      `canonical/agents/aid-developer/` removed (SG-05);
    - an installed skill byte-changed, or given `disable-model-invocation: true` (SG-06).
    (AC-6, AC-21, AC-23)
  - [ ] SG-06 checks each of the five tools at its own skills path (`.claude/skills/` for Claude Code,
    `.agents/skills/` for the others), for byte identity with `canonical/`, `name` equal to the folder and
    a non-empty `description` (AC-21).
  - [ ] Deterministic, with temporary folders removed and `HOME` pinned. It finishes inside
    `run-all.sh`'s 300-second budget.

### task-015: `test-skill-guide` in the feature-branch CI lane [CONFIGURE]

- **Waves:** stanza 5, derived 8. **Depends on:** task-014.
- **Source:** AC-21, AC-25.
- **Scope:** `.github/workflows/installer-tests.yml`: the bash-harness `SUITES` list gains
  `test-skill-guide`.
- **Suites updated in the same task:** `test-ascii-only.sh`, `test-ps51-compat.sh` and
  `test-aid-cli-parity.sh`, where they assert the workflow's text (S6).
- **Acceptance criteria:**
  - [ ] `grep -o 'test-skill-guide' .github/workflows/installer-tests.yml | wc -l` prints 1, inside the
    `SUITES=` line. Applying the edit twice changes nothing.
  - [ ] The lane's loop, `for s in $SUITES; do bash "tests/canonical/$s.sh"; done`, exits 0 when run in
    the scratch copy. No secret or token is added.
  - [ ] `test-ascii-only.sh` and `test-ps51-compat.sh` pass live. The pushed lane result is G0's check
    (AC-25).

### task-016: Feature 001 samples `001-01` to `001-08`: reading and matching a request [TEST]

- **Waves:** stanza 5, derived 7. **Depends on:** task-004, task-005 (the harness), task-010 (the
  finished behaviour, for the smoke run of D8).
- **Source:** AC-1, AC-2, AC-3, AC-4, AC-5, AC-7, AC-21.
- **Scope:** creates `tests/conversation/samples/feature-001/` `001-01-one-match.md` to
  `001-08-bare-idea.md`, plus any extra fixture they need. Each sample has:
  - frontmatter `id`, `covers` and `fixture`;
  - the sections `## User`, `## Answer sheet`, `## Expected outcome`, `## Must not` and `## Checks`.
- **Suites updated in the same task:** none.
- **Acceptance criteria:**
  - [ ] There are eight files with the spec's ids. Each `covers` equals F001 § 6 Criteria traceability:
    - `001-01`: AC-1;
    - `001-02` and `001-03`: AC-2;
    - `001-04`: AC-3;
    - `001-05`: AC-4;
    - `001-06`: AC-5;
    - `001-07`: AC-7 and AC-21;
    - `001-08`: AC-7.
  - [ ] `001-05`'s checks assert that no new `.aid/works/` folder exists and the answer cites sources.
    `001-07`'s checks assert a `Skill` call the agent made itself, and one approval before building.
  - [ ] No `## Answer sheet` names a skill, and no sample needs a network or a live tracker.
  - [ ] Each sample runs once (`--runs 1`) in a scratch copy (D8). A failure caused by the sample is
    fixed. A failure caused by the product is reported, not hidden. The 3-of-3 runs belong to the gate.

### task-017: Feature 001 samples `001-09` to `001-16`: phases, sources and closing [TEST]

- **Waves:** stanza 5, derived 7. **Depends on:** task-004, task-005, task-010.
- **Source:** AC-1, AC-14, AC-29.
- **Scope:** creates `001-09-bug-fix-phases.md` to `001-16-work-closes-done.md`, with their fixtures:
  - `001-15`: code, and no `.aid/knowledge/`;
  - `001-16`: a work whose tasks are all `Done`, in a project with no git remote;
  - `001-11` to `001-13`: the ticket as a file in the fixture (D9).
- **Suites updated in the same task:** none.
- **Acceptance criteria:**
  - [ ] There are eight files with the spec's ids. `covers`:
    - `001-09`, `001-10`, `001-15` and `001-16`: AC-14;
    - `001-11`, `001-12` and `001-13`: AC-29;
    - `001-14`: AC-1.
  - [ ] `001-11` checks for a `sources:` entry and the closed `qa:` entries. `001-15` checks that
    Preparation is offered before any Specification question and that no KB file is written before the
    user agrees. `001-16` checks that `STATE.yml` ends with `lifecycle: Completed` and that nothing is
    pushed.
  - [ ] No answer sheet names a skill. Each sample runs once in a scratch copy, as in task-016.

### task-018: KB test landscape for the two new suites, and the regenerated index [DOCUMENT]

- **Waves:** moved from stanza 4 to the end (D2), derived 9. **Depends on:** task-012, task-013,
  task-015, task-016, task-017.
- **Source:** AC-6, AC-21, AC-25 (KB current, no work id).
- **Scope:**
  - `.aid/knowledge/test-landscape.md`:
    - `tests/conversation/`: how to run it; that `run-all.sh` and CI never do; 3 of 3; the capture path;
    - `test-skill-guide.sh`: its groups, `COVERS` lines and lane;
    - `test-triage-routing.sh` is gone.
  - Any `module-map.md` test-coverage line for them.
  - Then `INDEX.md` is regenerated.
- **Suites updated in the same task:** any suite S6 lists that reads `test-landscape.md`.
- **Acceptance criteria:**
  - [ ] `test-landscape.md` names `python3 tests/conversation/run.py --feature 001` and
    `test-skill-guide.sh` with SG-01 to SG-06. `grep -c test-triage-routing .aid/knowledge/test-landscape.md`
    prints 0.
  - [ ] `bash .aid/runtime/scripts/kb/build-kb-index.sh --root .aid/knowledge --output
    .aid/knowledge/INDEX.md` has run. Running it again changes only the generated-at lines.
  - [ ] No work id, and the citation and frontmatter lints pass on the edited documents.

---

## 5. Coverage of the stanza

| Stanza item | Task(s) |
|---|---|
| `rules.md`: Handling a request, Skill guide, summary bullet, KI-001 | task-002 |
| `/aid-orchestrate` and five references; close minimum until delivery-010 | task-006 |
| Every `description:` in the what/when shape, builder template included | task-010 |
| `intent:` and `sources:`; `ticket_ref` out of every template; `attachment` part | task-003, task-007 |
| `aid-triage`, `aid-orchestrator` and `skill-routing.md` retired; `aid-monitor` re-pointed | task-009, task-008 |
| `test-skill-guide.sh` and its `SUITES` row; `tests/conversation/` | task-014, task-015; task-004, task-005 |
| Samples `001-01` to `001-16` | task-016, task-017 |
| Site, docs and KB edits; `INDEX.md` | task-011; task-012, task-013, task-018 |
| Gate: SG-01 to SG-06 | task-014 |
| Gate: template carries `intent:`/`sources:`, no `ticket_ref` under templates | task-003, task-007 |
| Gate: KI-001 | task-002 |
| G0: AC-24 rows | task-012 |
| G0: KB updated, `INDEX.md` regenerated | task-012, task-013, task-018 |
| G0: AC-22 names (`aid-orchestrate` is a verb, no acronym) | task-006 |
| Out of scope: the question protocol and step rules; the migration of existing works' `ticket_ref` | delivery-002; delivery-008 |

---

## 6. Delivery steps that are not tasks

These run around the tasks, by the main conversation (PLAN § How deliveries 001-009 are built):

1. **Start (delivery-001 only).** Write `--pipeline --field Phase --value Execute` and
   `--field "Active Skill" --value aid-execute`, then `--delivery-id 001 --lifecycle Executing`.
2. **The tasks**, one at a time in derived-wave and number order, each with its two state-only commits.
3. **Delivery verification** (`--lifecycle Gated`, one graded review of the delivery's diff, recorded
   with `--gate-field Grade`).
4. **The resync**, in its own session, committed alone as `delivery-001: resync`. It renders
   `aid-orchestrate` for all five tools. The install manifest then removes the installed `aid-triage`
   skill and `aid-orchestrator` agent, and the root `AGENTS.md` / `CLAUDE.md` regions get the 8-bullet
   summary.
5. **The gate**, in a new session:
   - the stanza's criteria, and samples `001-01` to `001-16` at 3 of 3 through
     `python3 tests/conversation/run.py --feature 001`;
   - G0 in full, including the scratch-copy generator comparison, the push, and the lane;
   - the baseline re-record (D11) and the tracking proof for task-001 to task-018.

---

## 7. Execution graph

| Task | Depends On |
|------|-----------|
| task-001 | -- |
| task-002 | task-001 |
| task-003 | task-001 |
| task-004 | task-001 |
| task-005 | task-001 |
| task-006 | task-002, task-003 |
| task-007 | task-003 |
| task-008 | task-006 |
| task-009 | task-006, task-007, task-008 |
| task-010 | task-009 |
| task-011 | task-008, task-009 |
| task-012 | task-007, task-009 |
| task-013 | task-006, task-009 |
| task-014 | task-010 |
| task-015 | task-014 |
| task-016 | task-004, task-005, task-010 |
| task-017 | task-004, task-005, task-010 |
| task-018 | task-012, task-013, task-015, task-016, task-017 |

| Can Be Done In Parallel |
|------------------------|
| task-002, task-003, task-004, task-005 |
| task-006, task-007 |
| task-010, task-011, task-012, task-013 |
| task-014, task-016, task-017 |

The derived waves below come from running `canonical/aid/scripts/execute/derive-waves.sh` on the table
above, in a scratch copy:

```text
wave 1: task-001
wave 2: task-002, task-003, task-004, task-005
wave 3: task-006, task-007
wave 4: task-008
wave 5: task-009
wave 6: task-010, task-011, task-012, task-013
wave 7: task-014, task-016, task-017
wave 8: task-015
wave 9: task-018
```

Parallel groups and shared files:

- **Coverage ledgers.** Tasks in one group may append different rows to the same coverage-ledger TSV.
- **Generated site files.** Tasks in one group may regenerate the same generated site files (§ 2).
- **No other shared file.** Every other shared file was resolved by a dependency: the agent table,
  `test-deploy-monitor-repurpose.sh`, `aid-describe/references/state-first-run.md`, `aid-monitor` and
  the KB index.
- **Q127 builds one task at a time.** The parallel column records independence. It does not speed up
  this delivery.

**Note for Step 5.** `derive-waves.sh` reads a table only under a `### delivery-NNN Execution Graph`
heading. Under `execution-graph-generation.md`'s example heading `#### Execution Graph`, it prints
nothing and still exits 0. So Step 5 writes each table under the `### delivery-NNN Execution Graph`
form, and checks that `--check` reports the delivery.

---

## 8. Decisions for the maintainer

| # | Decision | Recommendation | Alternative |
|---|---|---|---|
| D1 | The stanza's 5 waves become 9 derived waves. This comes from real dependencies inside stanza wave 3: `feedback-routing.md` is taken from the agent before the agent is deleted; `aid-monitor` stops naming triage before triage is deleted; and shared suites. It also comes from wave 5's suite-then-lane order. | Accept. Q127 builds one task at a time, so extra levels cost no time. | Merge tasks to flatten. That makes task-008 and task-009 too large for one review. |
| D2 | `test-landscape.md` would name `test-skill-guide.sh` in stanza wave 4, before the suite exists in wave 5. | Move the test-landscape edit and the `INDEX.md` regeneration to a last DOCUMENT task, task-018. The KB then never describes a missing suite. | Keep it in task-013, and accept a row that runs ahead of the tree until wave 5. |
| D3 | The one-line `SUITES` edit is CI configuration, not a test. | Keep it as its own CONFIGURE task, task-015 ("never mix types"). | Fold it into task-014 as test wiring, which saves one session and one review. |
| D4 | SG-04 exempt list. F001 exempts skills "a later feature of this work retires". F003, F005, F006 and F007 also drop rows for `aid-brainstorm`, `aid-specify`, `aid-plan` and `aid-execute` ("if it has one"; for `aid-brainstorm`, unconditionally). | Exempt only skills a later feature deletes or renames. The rebuilt skills get the what/when line now, one line each, and the later "row goes" steps become no-ops. | Also exempt the four rebuilt skills. That matches F003's wording literally, but the list is longer until delivery-009. |
| D5 | `test-doc-counts.sh` derives skill and agent counts and asserts them in `README.md` and `docs/`. task-006 (+1 skill), task-008 (-1 agent) and task-009 (-1 skill) each break it unless those numbers change in the same task. | The IMPLEMENT task re-syncs only the counted numbers, as a mechanical edit like a regeneration. The prose stays task-011's. | Treat it as type mixing, and add a DOCUMENT count task after each. That means 3 more sessions, and the suite is red between each pair. |
| D6 | Site placement of `aid-orchestrate`. The site tests pin `aid-triage` first in the Support group. | `aid-orchestrate` joins Support in task-006, and takes the first place when task-009 removes triage. | Another group. The site's curated roster then needs a new rule. |
| D7 | `write_backs:` is a top-level work key in F001 § 4, but the Files table names only `intent:` and `sources:` for the template. | Add `write_backs: []` to the work-state template in task-003, so the first write-back follows a template key in block style. | Leave it out, and let the first write-back create it. |
| D8 | Smoke runs of the samples inside task-016 and task-017. | One run of each sample in a scratch copy (16 runs), so the gate's 48 runs do not find sample defects. | Author only, and leave every run to the gate. |
| D9 | `001-11` to `001-13` need a ticket, but runs have no MCP server or live tracker. | The ticket is a file in the fixture (`ref` is a repo-relative path, `kind: ticket`). `001-12`'s write-back limit is then the real situation: the agent cannot attach. Live trackers are `009-11` and `009-12`. | The ticket text is pasted in the user's words. |
| D10 | The spec defines no permanent test for `run.py`. task-004's stub checks are not committed. | Add task-019 [TEST], `tests/canonical/test-conversation-runner.sh`, in derived wave 7 with task-014. It drives `run.py` with a stub `claude`, and checks the exits, the flags, the capture exclusions and 3 of 3 in CI. | Rely on task-004's in-session checks and the gate's live runs. |
| D11 | Who re-records `tests/coverage-baseline.tsv` and `tests/cost-baseline.tsv` (G0). | The gate session, after the resync. `coverage-parity.sh collect` runs every suite, and only then are the installed copies current. The commit is not resync-relevant. | A last task before the resync, which would record copy-reading suites against stale copies. |
| D12 | Measured at this base, 13 of 170 suites carry `# COVERS:`. So `select-suites.sh` selects nearly every suite for any change, and each task's test step is close to a full run split in two halves. | Keep the plan's rule as written: fail-safe selection, plus no suites for a task that changes only the work folder (task-001). | Narrow each task to the COVERS-selected suites plus task-001's Q106 map. That is faster, but it is a new selection rule the plan does not state. |
