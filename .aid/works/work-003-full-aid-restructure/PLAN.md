# Plan -- Conversational AID Restructure

All nine features ship as AID v4.0.0, in 14 deliveries built in order on the `work-003` branch.
The maintainer set the shape in the work `STATE.yml` `qa` Q111-Q127.

- Each delivery leaves the repository consistent, with the full suite green.
- Feature ids cite `REQUIREMENTS.md` § 11. Criteria cite § 9 `AC-N`.
- Sample ids name files under `tests/conversation/samples/`.
- Static-check ids name the groups each feature's Testing section defines.
- Q116: the cross-feature review of Feature 002's shared contracts runs in this plan's REVIEW.
- **Waves** in each stanza are groups of work in dependency order. A later wave needs the one before
  it; work inside one wave has no order. `/aid-detail` turns them into task `**Depends on:**` lines.
- **Same-task rule (Q106).** A task that rewrites, moves or deletes a file also updates every existing
  suite that asserts text in that file, and it is not `Done` while such a suite fails. A delivery's
  last wave adds only that delivery's *new* static-suite group, its unit cases and its samples.
- **Testing before the resync (Q131).** In the live work tree, `run_generator.py` runs only at a
  delivery's resync (Toolchain and Branching, The resync rule). Until then the live tree's installed
  copies (the managed set `sync_dogfood.py` names: `.agents/skills/`, `.claude/skills/aid-*`,
  `.aid/runtime/`, `.claude/agents/`, `.cursor/agents/`, `AGENTS.md`, `CLAUDE.md`) and its rendered
  `profiles/` are one resync behind `canonical/`. One rule holds for **every suite run before the
  delivery's resync**, whoever runs it: a task's tests, and from delivery-010 on F007's full suite at
  FINAL, each re-run after a fix round, a correction call's run and F008's run on a merged tree.
  - A **copy-reading suite** reads what the resync writes, from its own repository: `profiles/` or an
    installed copy, directly, or through a clone of the repository's head or a release staged from it
    (`release.sh` takes each tool's artifacts from `profiles/<tool>`, and its non-stage modes re-render
    and reject drift against the head). It runs in a **scratch copy with a repository of its own**,
    after `run_generator.py` there. Examples are `test-dogfood-byte-identity.sh`,
    `test-work-state-template.sh`, `test-connector-skills-structural.sh`, `test-cutover-no-dangling.sh`
    and `test-release-install-e2e.sh`.
  - **Every other suite runs in the live tree.**
  - A task runs the suites whose `# COVERS:` headers name the files it changed (`test-landscape.md`
    § Running only the suites a change can affect), each where this rule puts it. `/aid-detail` writes
    this rule into every task file's test steps, so each builder's executor follows it.
  - **How the copy is made:**
    ```sh
    S=.aid/.temp/scratch/task-NNN; rm -rf "$S"; mkdir -p "$S"
    tar -C <work-003 worktree> --exclude=./.git --exclude=./.aid/.temp -cf - . | tar -C "$S" -xf -
    git -C "$S" init -q && git -C "$S" add -A && git -C "$S" -c user.name=scratch -c user.email=scratch@local commit -qm scratch
    (cd "$S" && python3 .claude/skills/generate-profile/scripts/run_generator.py)
    git -C "$S" add -A && git -C "$S" -c user.name=scratch -c user.email=scratch@local commit -q --allow-empty -m resync
    ```
    - The copy's own `run_generator.py` runs, from inside the copy. The generator renders into its
      working folder, but starts `sync_dogfood.py` from its own folder; the live tree's script, run
      there, would resync the live tree.
    - The second commit makes the copy's head the tree the resync will commit. A suite that clones the
      head, or checks render drift against it, then sees that tree.
    - The copy-reading suites run from inside the copy (`cd "$S"`), because `run-all.sh` re-invokes
      itself by the path it was started with. The copy is deleted (`rm -rf "$S"`) once they have run,
      and before any live suite runs, so no suite walking the live tree finds it.
  - **Why the live work cannot be reached.**
    - The worktree's `.git` file, which points into this repository's object store and worktree list,
      is not copied.
    - The copy's `git worktree list` names only the copy, so the format-6 steps reach no other work.
      They address works through the main folder and "each worktree `git worktree list` registers".
    - `sync_dogfood.py` resolves its target from its own path, which is inside the copy.
    - So every migration it runs (from delivery-005 on) rewrites only the copy's files. The live
      `work-003` state is never touched.
  - **The whole suite before a resync** is the same rule over every suite, reported as one result.
    `run-all.sh` cannot choose suites: its only option is `-v`, with `AID_TEST_JOBS` for parallelism,
    and it runs every `tests/canonical/test-*.sh` beside it. So the run has three steps:
    1. **Scratch half.** In the copy, every suite outside the copy-reading set is deleted, and the
       copy's `run-all.sh` runs the rest.
    2. **Live half.** `run-all.sh` runs in the live tree. The copy-reading suites run there too, since
       it cannot skip them, but their live results are dropped.
    3. **One result.** The failing suites are the scratch half's failures plus the live half's
       failures outside the set, by name. The run exits 0 only when there are none. When the generator
       fails in the copy, that failure is listed, and the copy-reading suites are listed as not run.
  - **Which suites are in the set.** A search that errs wide picks every suite whose text names
    `profiles/`, `release.sh` or an installed path.
    - A suite picked wrongly gets in the copy the result it would get in the live tree after the
      resync. No suite reads its repository's history or other worktrees: its git uses on its own root
      are `status --porcelain` counts, `rev-parse`, a temporary tag and a clone of the head, and the
      copy's repository answers them alike.
    - A copy-reading suite the search misses fails, or passes on stale copies, in the live half. G0's
      run after the resync, where nothing is stale, catches either.
  - **The driver.** `full-suite.sh` in the work folder runs the three steps. The main conversation
    saves it in delivery-010's gate session and records it as the work's full-suite command
    (switch questions). Its text:
    ```bash
    #!/usr/bin/env bash
    # The full suite before a delivery's resync (PLAN.md, Testing before the resync).
    set -uo pipefail
    cd "$(git rev-parse --show-toplevel)" || exit 2
    P='profiles/|release\.sh|\.aid/runtime|\.agents/skills|\.claude/skills|\.claude/agents|\.cursor/agents|AGENTS\.md|CLAUDE\.md|aid-manifest'
    mapfile -t COPY < <(grep -lE "$P" tests/canonical/test-*.sh)
    in_copy() { printf '%s\n' "${COPY[@]}" | grep -qxF "$1"; }
    fails() { sed -n '/CANONICAL SUITES FAILED:$/,$ s/^  - //p' "$1"; }
    failed=(); S=.aid/.temp/scratch/full-suite; L="$(mktemp)"
    # 1. Scratch half: the copy-reading suites, on the copy after its own generator.
    rm -rf "$S"; mkdir -p "$S"
    tar --exclude=./.git --exclude=./.aid/.temp -cf - . | tar -C "$S" -xf -
    g() { git -C "$S" -c user.name=scratch -c user.email=scratch@local "$@"; }
    g init -q && g add -A && g commit -qm scratch
    if (cd "$S" && python3 .claude/skills/generate-profile/scripts/run_generator.py); then
      g add -A && g commit -q --allow-empty -m resync
      for f in "$S"/tests/canonical/test-*.sh; do in_copy "tests/canonical/${f##*/}" || rm -f "$f"; done
      (cd "$S" && HOME="$(mktemp -d)" bash tests/run-all.sh) | tee "$L"; rc=${PIPESTATUS[0]}
      mapfile -t F < <(fails "$L"); failed+=("${F[@]}")
      [ "$rc" -ne 0 ] && [ ${#F[@]} -eq 0 ] && failed+=("run-all.sh in the scratch copy (exit $rc)")
    else
      failed+=("run_generator.py in the scratch copy" "${COPY[@]/%/ (not run)}")
    fi
    rm -rf "$S"
    # 2. Live half: every other suite. run-all.sh cannot skip, so the copy-reading lines are dropped.
    HOME="$(mktemp -d)" bash tests/run-all.sh | tee "$L"; rc=${PIPESTATUS[0]}
    mapfile -t F < <(fails "$L")
    for t in "${F[@]}"; do in_copy "$t" || failed+=("$t"); done
    [ "$rc" -ne 0 ] && [ ${#F[@]} -eq 0 ] && failed+=("run-all.sh in the live tree (exit $rc)")
    rm -f "$L"
    # 3. One result.
    echo "=================================================="
    total=$(ls tests/canonical/test-*.sh | wc -l)
    if [ ${#failed[@]} -eq 0 ]; then
      echo "FULL SUITE PASSED: ${#COPY[@]} suites in the scratch copy, $((total - ${#COPY[@]})) in the live tree"; exit 0
    fi
    echo "FULL SUITE FAILED (${total} suites):"; printf '  - %s\n' "${failed[@]}"; exit 1
    ```
  - **Against the `not taken` baseline.** This work records its full-suite baseline as `not taken`
    (switch questions), so F007 shows every FINAL failure at the approval, each with a recommendation
    (F007 § 2 step 9). Under this rule no copy-reading suite meets a stale copy, so each listed failure
    is the work's own. The one exception is a suite the search missed. The run names it, it is added to
    the driver's search (a work-folder change, not resync-relevant), and the run repeats.
  - **After the resync** the live tree's copies are current. So G0's `run-all.sh` runs every suite in
    the live tree, and no scratch half is needed there. G0 uses a scratch copy only to compare its
    output with the live trees.
- **AC citations.** A gate criterion cites only the ACs its own checks verify in that delivery. For a
  sample, these are the ACs its `covers` field names in the spec. When the delivery builds only part
  of an AC, the criterion names that part as a clause, for example "AC-37 (resume clause)". An AC
  that a later delivery completes is named as such.

## Common Gate (G0)

Every delivery's gate ends with G0. G0 is checked on a tree whose last resync-relevant change is the
delivery's resync, in a session started after it (The resync rule). G0 holds when all of these are
true:

- `HOME="$(mktemp -d)" bash tests/run-all.sh` exits 0 in the live tree, with every suite run there
  (Testing before the resync, After the resync), and the site `npm test` passes, both run locally. The
  canonical lane does not run on feature branches (`test-landscape.md` § CI Lanes and Where They Run).
- `run_generator.py`, run in a scratch copy made as "Testing before the resync" says, produces
  `profiles/` and installed trees identical to the live ones.
- `installer-tests.yml` is green for the delivery's commits on `work-003`. (AC-25) It covers what CI
  really runs:
  - the Linux bash-harness job runs its `SUITES` list, where PowerShell halves run under `pwsh` 7.
    The delivery that adds a static or migration suite adds it to `SUITES`, as each spec's Testing
    section requires;
  - the Windows job runs `tests/windows/Test-AidInstaller.ps1` and `Test-InstallProvisioning.ps1`
    under `pwsh` and Windows PowerShell 5.1. The delivery that adds a format-6 step adds a case for it
    to `Test-AidInstaller.ps1`, so that step's PowerShell twin runs natively under 5.1 (Q126);
  - other PowerShell code is checked for 5.1 only statically, by `test-ps51-compat.sh` in
    `run-all.sh`.
- **How the lane gets the commits:**
  - Deliveries 001-009: the maintainer pushes `work-003` to `origin` after the gate's local checks
    pass. No pull request exists yet.
  - From delivery-010 on: `work-003` reaches `origin` only through `/aid-monitor-pipeline` at a
    milestone (`push-approved.sh`, AC-42). The lane result of that push is read at the next
    milestone's collect step, or at CI's WATCH after delivery-014. A red lane there becomes a
    correction task, and a "no" to the push question carries this G0 item to the next milestone that
    pushes.
- No skill name the delivery adds uses an acronym, and every one is a verb or KB plus a verb. No
  artifact name it adds uses an acronym. (AC-22)
- Every slash name the delivery retires has its row in the old -> new table in
  `.aid/knowledge/backlog.md` § Next Release. (AC-24)
- The KB documents the delivery's spec lists are updated with no work id, and `INDEX.md` is
  regenerated. From delivery-005 on, `kb.html` is also re-rendered by `render-kb-view.sh`.
- `tests/coverage-baseline.tsv` and `tests/cost-baseline.tsv` are re-recorded, and every removed
  assertion has its row in `tests/coverage-accepted-removals.tsv`.
- Every conversation sample the stanza names passes 3 runs of 3 (NFR-T). Every sample still waiting
  has a row in `tests/conversation/deferred.tsv` naming what it waits for.
- Every earlier delivery's static-check group still passes. For a split feature (Q113, Q115), its
  suite holds one group per part, and each group is added in the delivery that lands its part.
- **Deliveries 001-009, built directly (Q127): the tracking proof (Q125).** For every task of the
  delivery:
  - `git log --format=%s -- <the file holding the task's state>` shows two commits of that file alone,
    `task-NNN: In Progress` then `task-NNN: In Review`, before the task's own commit;
  - in the task's own commit, the state file holds the task's terminal state and a review grade at or
    above `minimum_grade` (the task's `review` field);
  - from delivery-008 on, the work `STATE.yml` `reviews` also holds an entry noting `task-NNN verify`.
    The work-file `--review` mode reaches the installed writer only with delivery-007's resync. It
    adds the `reviews` key to this work's file, which has none (F005 § 4, Q130).

  **Which file holds the task's state.** The resync is no task (The resync rule), so no task straddles
  delivery-008's file switch:
  - deliveries 001-008: every task ends before delivery-008's resync, and its file is its per-task
    `STATE.yml`. The migration deletes that file, but `git log -- <its path>` still reads its history;
  - delivery-009: every task runs after that resync, and its file is the work `STATE.yml`.

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
- New `tests/canonical/test-skill-guide.sh` (SG-01 to SG-06), added to `SUITES` in
  `installer-tests.yml`, and the conversation suite `tests/conversation/` (`run.py`, the simulated
  user, the judge). (AC-21, NFR-T)

**Out of scope:**
- The question protocol and the step rules (delivery-002).
- The `ticket_ref` -> `sources:` migration of existing works (delivery-008).

**Waves:**
1. Re-run the spec's stated searches (triage, orchestrator and `ticket_ref` sites) and reconcile the edit list.
2. The rules sections, the templates (`intent:`, `sources:`, no `ticket_ref`) and the conversation-suite harness. Each task updates, in that same task, the suites asserting the text it changes, for example the summary-count suites of the F001 Migration table.
3. `/aid-orchestrate` and its references, the re-pointed skills and the retirements, each with its asserting suites. These need the rules sections and templates.
4. Skill descriptions, the builder template, and the site and KB edits.
5. The new `test-skill-guide.sh` and the delivery's sample files, then the delivery's resync step.

**Gate Criteria:**
- [ ] `tests/canonical/test-skill-guide.sh` SG-01 to SG-06 pass:
  - `## Handling a request` counts at most 20 lines;
  - the guide names exactly the skills in `canonical/skills/`, both ways;
  - no `aid-triage` and no `aid-orchestrator` exist;
  - every skill is installed for all five tools.
  (AC-6, AC-21, AC-23)
- [ ] Samples `001-01` to `001-16` each pass 3 of 3 through `tests/conversation/run.py --feature 001`. (AC-1, AC-2, AC-3, AC-4, AC-5, AC-7, AC-14, AC-21, AC-29)
- [ ] `canonical/aid/templates/work-state-template.yml` carries `intent:` and `sources:` in block style, and `git grep ticket_ref -- canonical/aid/templates` finds nothing. (AC-29)
- [ ] `canonical/aid/rules.md` § Tracking discipline names the work state file `STATE.yml`, not `STATE.md`. (KI-001)
- [ ] G0 passes.

### delivery-002: One work record and one set of step rules (Feature 002, engine)
- **What it delivers:** Every work gets a record -- type, running skill, step -- from the moment it is created; every skill writes its step before working and says, through the new advance words, which step comes after a pause; any session resumes exactly where the record says; the phase names become Definition, Specification, Planning, Building, CI everywhere; the question protocol, the step rules and the approval and merge rules are written once.
- **Features:** feature-002-step-by-step-decisions (engine part)
- **Depends on:** delivery-001
- **Priority:** Must

**Objective:** This delivery puts in place the contract every later phase skill is rebuilt on:

- `question-protocol.md` and `skill-steps.md`;
- the writer modes;
- the work record, created only by the gate, kept current by every skill, and the only thing that
  decides where a work resumes.

Q115 limits the engine to "protocol, skill-steps.md, writer modes, work record, gate". The maintainer
added three adjustments to the engine:

- step saves in every skill (Q121);
- the phase renames at every site, the dashboard included (Q121);
- translating the advance words (Q122).

The Notes explain why each is needed.

**Scope:**
- **Shared rules:**
  - new `canonical/aid/templates/question-protocol.md`;
  - new `canonical/aid/templates/skill-steps.md`, including § The work record, the advance words and
    § When approvals happen, with the never-merges rule;
  - new `project-state-template.yml`.
- **The writer:** `writeback-state.sh` gains the modes `--create`, `--step`, `--handoff`,
  `--handoff-return`, `--reroute`, `--check`, `--repair`, `--ask` and `--answer`.
  - New exits 7, 8 and 9; every write is atomic.
  - Only the new phase names are accepted. The dashboard fork follows with the new names and keeps
    `Deploy`.
- **The work record:**
  - The gate's § 3a runs `--create`, and every allocation point goes through it.
  - `aid-describe --reset` is removed.
  - § 3b routes by the record only: the resume table, `--check` with a confirmed `--repair`, and the
    legacy block.
  - The starters' continuation lines change to match.
  - Every skill's § State Detection only shapes the entry step, or validates the saved step.
  - The seven kept finishers finish through the writer.
  - `/aid-orchestrate` starts, resumes and cancels works. The `rules.md` bullets name
    `question-protocol.md` and the merge rule.
- **SS-02, as the spec states it** (F002 § 8): "every `SKILL.md` with a Dispatch table or a
  `## State:` section, and, while they exist, `shortcut-engine.md` (deleted by Feature 009) and
  `design-lifecycle.md` (deleted by Feature 004), cite `skill-steps.md`".
  - No exempt list covers SS-02, so this delivery converts every such file. That includes the
    `## State:` skills a later delivery rebuilds or retires: `aid-brainstorm`, `aid-design` and every
    `aid-design-*`, the KB `create`/`update` skills, `aid-create-document` and `aid-update-document`.
  - No generated doorway skill has a Dispatch table or a `## State:` section today.
  - `skill-steps.md` is cited "in place of" the chaining file (F002 § 4), so every citation of
    `state-machine-chaining.md` is re-pointed to `skill-steps.md` in the same edit. The file itself is
    deleted in delivery-003.
- **Advance words:** every `**Advance:**` line is translated one for one:
  - `PAUSE-FOR-USER-DECISION` becomes `ASK`, keeping the step it named;
  - `PAUSE-FOR-USER-ACTION` becomes `WAIT`;
  - a pause that points at another skill becomes `ASK` then `HALT`.
  `site/scripts/lib/flow-graph/advance.mjs` and `flow-advance.test.mjs` learn the words, and the flows
  are regenerated by `site/scripts/gen-skills.mjs`.
- **Phase sites:**
  - the nine `--field Phase --value` writes and the two literal seeds;
  - the gate;
  - `aid-deploy` `references/state-idle.md`;
  - both readers' `Phase` enum and old-name map, inside `legacy-phase-map` markers;
  - `home.html`: `PHASE_ORDER`, `PRE_EXEC_STEPS`, and one stage rail per work drawn from
    `intent.phases`, which replaces the lite rail (Q75).
- **New suites:**
  - `tests/canonical/test-skill-steps.sh` engine group (E): SS-02 without its chaining-file clause,
    SS-03, SS-08, SS-11, SS-12, SS-14;
  - `skill-steps-exempt.tsv`;
  - `test-never-merges.sh` NM-01 to NM-04;
  - `test-deferred-tests.sh` DT-01 and DT-02, with `tests/conversation/deferred.tsv`;
  - `dashboard/server/tests/test_home_stage_rails.mjs`.
  Each new static suite is added to `SUITES`.

**Out of scope:** All of these are delivery-003:
- banners and "you are here" maps;
- deleting `state-machine-chaining.md`;
- adopting the protocol in each asking skill, and dropping the host question pickers;
- the question-record sites (KI-003);
- the interviewer;
- review focus;
- the dashboard's new work fields.

**Waves:**
1. Re-run the spec's stated searches: phase sites (SS-11 forms), allocation points (SS-14), finishers (SS-12), `PAUSE-FOR-USER` lines (SS-03), and the `SKILL.md` files with a Dispatch table or `## State:` section (SS-02). Reconcile the edit list.
2. The writer modes, the phase-name enum and the dashboard fork. Then `question-protocol.md`, `skill-steps.md`, `project-state-template.yml`, the work-state template, and `advance.mjs` with its test. Both groups only add, and the next wave consumes them.
3. The gate's § 3a and § 3b and `/aid-orchestrate`, with `test-work-initiation-gate.sh` in the same task. These need the writer's `--create`, `--check` and `--repair`.
4. Every allocation point, continuation line, State Detection section, `skill-steps.md` citation, advance word, finisher and phase write site, and both readers' phase sites. Each task updates the suites asserting those texts, for example `test-pipeline-status-walkthrough.sh` and `test-writeback-state.sh`. These need the converted gate and the new names. The flows are regenerated at the end of the wave.
5. The new group E, NM, DT and stage-rail suites, the writer and gate units, and the delivery's sample files. Then the delivery's resync step.

**Gate Criteria:**
- [ ] `test-skill-steps.sh` group E passes:
  - every `SKILL.md` with a Dispatch table or a `## State:` section, plus `shortcut-engine.md` and
    `design-lifecycle.md`, cites `skill-steps.md`;
  - every `**Advance:**` word is one of `CHAIN`, `ASK`, `WAIT`, `PASS`, `CALL`, `HALT`;
  - both templates parse through the dashboard reader with no warning;
  - no old phase name appears as data or logic;
  - no hand-written `lifecycle: Completed` or `Canceled` exists outside the exempt list;
  - only the gate creates a work's `STATE.yml`.
  (AC-37, resume clause)
- [ ] `test-never-merges.sh` NM-01 to NM-04 pass, and only the `aid-housekeep` and `aid-execute` exemptions fire. (AC-11, never-merges clause)
- [ ] `test-writeback-state.sh` passes for every new mode:
  - `--create` exits 5, 4 or 8 on a bad call;
  - a failed write leaves the file byte-for-byte unchanged;
  - `--check` exits 9 or 0;
  - `--handoff-return` resolves nested calls newest first, and exits 7 with no open call.
  `test-work-initiation-gate.sh` has a passing `--check` fixture for each resume-table row. (F002 § 8 unit tests; AC-38 completes at delivery-007 with `002-12` and at delivery-009 with `002-13`)
- [ ] Both dashboard readers map old and new phase names to the five new members, and pass parity. `test_home_stage_rails.mjs` marks the Building stage for a work without Definition that is at `Building`. `flow-advance.test.mjs` passes. (F002 § 2 phase sites; AC-41 completes at delivery-003)
- [ ] Samples `002-05`, `002-20` and `002-21` each pass 3 of 3. Every other Feature 002 sample has a `deferred.tsv` row, and DT-01 passes. (AC-11, never-merges clause; AC-37, resume clause)
- [ ] G0 passes.

**Notes:**
- **Q121 keeps the step saves and the phase renames here.**
  - § 3b resumes "`active_skill` at its saved `step`". If today's skills did not write their step on
    entry, a resumed work would land at its creation step.
  - The writer refuses old names. Every write site and both readers must change with it, or writes
    fail and the dashboard shows `Unknown`.
- **Q122 moves the advance-word translation here.**
  - Once detection stops routing, a skill resumes at its saved step.
  - Only `ASK`, which saves the step a pause names before asking, makes a resume go on to that step.
  - Under today's `PAUSE-FOR-USER-*` lines, re-running a paused skill would return to the step that
    paused, in every skill installed between the two deliveries.
- The sweep keeps everything the user sees and every cleanup.

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
  engines. `state-machine-chaining.md` is deleted; delivery-002 already re-pointed its citations to
  `skill-steps.md`. (AC-37)
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
  SS-04, SS-05, SS-06, SS-07, SS-09, SS-10, SS-13.

**Out of scope:** The `PASS` and `CALL` edges of the rebuilt phase skills (deliveries 004-013).

**Waves:**
1. Re-run the spec's stated searches: SS-01 forms, interviewer sites, question-record sites, `AskUserQuestion` users, `reviewer-brief.md` files and citations of the chaining file. Reconcile the edit list.
2. `agent-boilerplate.md`'s new section. The agent edits depend on it.
3. Two groups that do not depend on each other. First, the sweep over skills, shared engines, agents and briefs: banners, the chaining file, the protocol line, question-record sites, the interviewer removed, `### What to report`. Second, the dashboard work fields. Each task updates the suites asserting the texts it changes, for example `test-describe-full-only.sh` and `test_index_html.py`.
4. The new group S and dashboard cases, and `tests/conversation/protocol-checks.md`. The delivery's samples were written in delivery-002 (Q135); here their `deferred.tsv` rows go. Then the delivery's resync step.

**Gate Criteria:**
- [ ] `test-skill-steps.sh` group S passes, and group E still passes:
  - no banner form appears;
  - `state-machine-chaining.md` is absent and cited nowhere;
  - no `AskUserQuestion` appears;
  - the word `interviewer` appears nowhere in scope;
  - no delivery-level `qa` write exists;
  - every asking skill has a sample or a `skill:` row;
  - every reviewer file has `### What to report`.
  (AC-8, AC-28, AC-37 no-banner clause, AC-40, AC-46)
- [ ] Samples `002-01` to `002-04` and `002-14` to `002-19` each pass 3 of 3, and the judge applies `tests/conversation/protocol-checks.md` to each. (AC-8, AC-28)
- [ ] Dashboard fixtures show the card lines for a work at each phase, during a call, and with a missing and an inconsistent record. Both readers pass parity, and SS-07 passes for `chat-node/`. (AC-41)
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
- New `test-idea-shaping.sh` (ID-01 to ID-07) and `test-idea-drafts.sh`, added to `SUITES`.

**Out of scope:** The KB-update branch's own skill (delivery-005). The draft's deletion at an approval
is checked at delivery-007 (`003-09`) and delivery-009 (`003-10`).

**Waves:**
1. Re-run the spec's stated re-pointing searches for `aid-describe`, `aid-design` and `.aid/design/`, and reconcile the edit list.
2. `idea-drafts.sh`, the writer fields, `kind-catalog.yml`, `design-seed.md` and the README template.
3. `aid-brainstorm` and its references, the `skill-steps.md` deletion rule, the routing rows and the gate's legacy rows. Each task brings its asserting suites. These need wave 2.
4. The retirements and re-pointing, each with the suites that name the retired skills (F003 § 6 Tests). These need the new skill in place.
5. The new `test-idea-shaping.sh` and `test-idea-drafts.sh` and the delivery's sample files. Then the delivery's resync step.

**Gate Criteria:**
- [ ] `test-idea-shaping.sh` ID-01 to ID-07 pass:
  - `aid-describe`, `aid-design` and `aid-design-*` are absent;
  - no `verb: design` row remains;
  - only `idea-drafts.sh` commits under `.aid/design/`;
  - the brainstorm step table is START, CONVERSE, CHECK, FINISH.
  (AC-43; AC-17 draft-location clause)
- [ ] `test-idea-drafts.sh` passes:
  - `keep` commits only the draft's path on the work branch;
  - `delete` of a loose draft makes no commit;
  - exits 2, 3, 4 and 5 change nothing;
  - the script has no `git push`.
  (AC-17 draft-location clause; KI-004)
- [ ] The writer accepts `"Idea Draft"` and `"Side Idea"` with `--` or a valid identity, and exits 4 on anything else. Each new legacy row has a passing `--check` fixture. (AC-37 resume clause)
- [ ] Samples `003-01` to `003-05` each pass 3 of 3, and `001-08` passes again. (AC-7, AC-17 draft-location clause, AC-28, AC-37, AC-43)
- [ ] G0 passes.

### delivery-005: The four KB skills on one KB state file (Feature 004, first part)
- **What it delivers:** The KB is built, queried, updated and shown through `/aid-kb-build`, `/aid-kb-query`, `/aid-kb-update` and `/aid-kb-show`, run by the agent's own judgment; `kb.html` is rendered by a script, the same bytes for the same KB, at every build and update; KB state lives in `.aid/knowledge/STATE.yml`; summarize and housekeep retire.
- **Features:** feature-004-kb-management (KB skills, renderer and state file)
- **Depends on:** delivery-004
- **Priority:** Must

**Objective:** Move the KB onto its four skills and its new state file in one step (Q117).

- The new skills read and write only `.aid/knowledge/STATE.yml`.
- Every skill writing today's `STATE.md` (discover, update-kb, housekeep, summarize, ask) is replaced
  in this same delivery.
- The KB step of format 6 converts existing projects, this repository among them, at this delivery's
  resync.

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
- **Retired:**
  - `aid-summarize` and `aid-housekeep`;
  - `summarize/`, the housekeep scripts except `cleanup-classify.sh`, `discover-preflight.sh`;
  - the dropped `knowledge-summary/` files;
  - the root `package.json` and the workflow steps that ran the view's Playwright check.
  NM-03's `aid-housekeep` exemption goes. (AC-15)
- **Format 6:**
  - every carrier reads 6; STEP 0 accepts `STATE.yml`;
  - the KB step converts `STATE.md`, in bash and PowerShell, with a case in `Test-AidInstaller.ps1`;
  - this repository's KB is converted and its `kb.html` re-rendered;
  - the suites that assert format 5 move to 6 with the carriers (F004 § 7, Re-pointed suites).
  (AC-25)
- **Dashboard:** both readers read `STATE.yml`, with a `legacy-kb-state` block for `STATE.md`. They
  use the new KB status waterfall, including `Growing`, and the KB card. `knowledge.source` and
  `knowledge.last_update` are no longer read; `complexity-score.sh` stops reading KB state.
- **Orchestration:**
  - `aid-orchestrate` offers to resume a build and routes open KB questions;
  - the knowledge-update row of `size-and-route.md` names `/aid-kb-update`, and it offers the build
    first when there is no KB;
  - `feedback-routing.md`;
  - the KB-update branch of brainstorm's FINISH;
  - the `rules.md` tracking and connectors lines.
- **Re-pointing** applies to every retired or moved name of this part.
- **Suites:** `test-kb-skills.sh` group K1 (KB-01 and KB-02 for this part's names, KB-03, KB-04,
  KB-05, KB-06 for build resume and knowledge-update routing, KB-08); `test-render-kb-view.sh`;
  `test-kb-commit.sh`; `test-kb-state-migration.sh` for the KB step. Each is added to `SUITES`.

**Out of scope:** Delivery-006 adds:
- KB documents created by `/aid-kb-update`;
- the 14 KB `create`/`update` skills and `design-lifecycle.md` retired;
- the roadmap and backlog templates;
- the new-project skeleton;
- the drift check at work start, with its baselines;
- the parent branch (Q60).

**Waves:**
1. Re-run the spec's stated re-pointing searches for the retired names, the moved references, `.aid/knowledge/STATE.md`, and `AID_SUPPORTED_FORMAT` or `format_version: 5`. Reconcile the edit list.
2. `kb-state-template.yml`, the writer's `--kb` modes, `kb-commit.sh`, `render-kb-view.sh` and `build-kb-index.sh`, each with its asserting suites.
3. The four skills, the `skill-steps.md` and `question-protocol.md` edits, and the orchestration and brainstorm edits. Each moved skill is moved together with the suites that follow its text (F004 § 7, Re-pointed suites). These need wave 2.
4. Two groups. The format-6 carriers and KB step (bash, PowerShell, the `Test-AidInstaller.ps1` case) together with every suite asserting format 5. Both dashboard readers with their KB tests and fixtures. Then the retirements and re-pointing, each retirement with the suites it retires or changes.
5. The new group K1 and the new unit suites, and the delivery's sample files. Then the delivery's resync step: it converts this repository's KB, and `kb.html` is then rendered.

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
- [ ] `test-kb-state-migration.sh` passes for the KB step, with bash and PowerShell byte-identical and a second run changing nothing. The `Test-AidInstaller.ps1` KB-step case passes under `pwsh` and 5.1. This repository has `.aid/knowledge/STATE.yml` and no `STATE.md`. (AC-25)
- [ ] Dashboard fixtures for each KB status, a `Growing` skeleton and a legacy `STATE.md` pass in both readers, including the parity tests. (AC-15)
- [ ] Samples `004-01`, `004-02`, `004-03`, `004-04` and `004-07` each pass 3 of 3, and `001-05` and `001-15` pass again. (AC-4, AC-14, AC-15, AC-28, AC-37)
- [ ] G0 passes.

**Notes:**
- **Q117 moves the KB state file, the format-6 KB step and the dashboard's KB reads here**, for three
  reasons:
  - The four skills write every state change through `--kb`. For the build the spec says
    "every state write goes through `--kb`", and the same holds for the update and query skills.
  - Today's `STATE.md` is written by the very skills this part replaces.
  - Under the spec's "No KB: one rule", this repository would otherwise have no KB from this
    delivery's resync onward.

### delivery-006: The KB grows and stays current (Feature 004, second part)
- **What it delivers:** `/aid-kb-update` creates and registers new KB documents, so the KB `create`/`update` skills retire; roadmap and backlog are ordinary documents ("work on the next backlog item" works); a new project starts with a committed `Growing` KB skeleton that holds no document; at work start the agent offers to fix documents that drifted from the code; new works branch from the main folder's current branch.
- **Features:** feature-004-kb-management (growth, roadmap and backlog, drift, parent branch)
- **Depends on:** delivery-005
- **Priority:** Must

**Objective:** Finish Feature 004 with everything that makes the KB grow and stay current, on top of
the skills and state file delivery-005 installed (Q117). It stands alone: after delivery-005, a new
document can still be written by today's KB `create` skills, and this delivery replaces them.

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
- The drift check in `start-or-resume.md` (Q57). Format 6 gains the step that back-fills
  `approved_at_commit:` baselines. (AC-15)
- Q60:
  - `worktree-lifecycle.sh` `create` uses the main folder's checked-out branch;
  - `--create --parent-branch`;
  - `pipeline.parent_branch`;
  - format 6 fills it for existing works, with a `Test-AidInstaller.ps1` case for both new steps;
  - `aid-kb-update` START's removed-KB safety net.
- `test-kb-skills.sh` group K2 (KB-01 and KB-02 for this part's names, KB-06 for drift, new project
  and backlog, KB-07). `test-worktree-lifecycle.sh` gets its Q60 cases.

**Out of scope:** The KB calls made by Specification and Building (deliveries 007 and 009). Recording
facts in a new project is checked at delivery-007 (`004-10`) and delivery-009 (`004-11`).

**Waves:**
1. Re-run the spec's stated searches for the KB `create`/`update` skills and `design-lifecycle.md`, and reconcile the edit list.
2. Two independent groups, each with its asserting suites. First, `worktree-lifecycle.sh` with `--create --parent-branch` and the work-state key. Second, `kb-commit.sh --new-project`, `new-document.md` and the two document templates.
3. The new-project step in the gate, the drift check, the `check-intent.md` backlog read, and the format-6 baselines and parent-branch steps (with the `Test-AidInstaller.ps1` case). These need wave 2.
4. The retirements and re-pointing, each with the suites that name the retired skills.
5. The new group K2 and the new unit cases, and the delivery's sample files. Then the delivery's resync step.

**Gate Criteria:**
- [ ] `test-kb-skills.sh` group K2 passes, and group K1 still passes:
  - no KB `create`/`update` skill and no `design-lifecycle.md` exists;
  - `knowledge-base/roadmap.md` has `## MVP`;
  - the gate's § 3a runs the new-project step before creating the worktree;
  - `start-or-resume.md` names `kb-freshness-check.sh`.
  (AC-39; AC-18, nothing-up-front clause)
- [ ] `test-worktree-lifecycle.sh` passes. With the main folder on a branch other than `master`, `create` branches from that branch; with no branch checked out, it exits 2. (Q60)
- [ ] `test-kb-commit.sh --new-project` commits only `.aid/settings.yml` and the KB skeleton, which holds no document. (AC-18, nothing-up-front clause)
- [ ] `test-kb-state-migration.sh` passes for baselines and `pipeline.parent_branch`, in the main folder and in a registered worktree, with a re-run changing nothing and bash and PowerShell byte-identical. The `Test-AidInstaller.ps1` cases pass under `pwsh` and 5.1. (AC-25)
- [ ] Samples `004-05`, `004-06`, `004-08`, `004-09` and `003-11` each pass 3 of 3. `skill-steps-exempt.tsv` holds no row whose owner is Feature 004. (AC-15, AC-28, AC-39, AC-43)
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
- Writer: `--review` on the work file, adding the `reviews` key when a work file has none (Q130), and
  `"Effort Check"`. The template drops `interview`,
  `features` and `review_history`. (AC-44)
- `slice-requirements.sh` reads the unsplit shape.
- `skill-steps.md`: the business-part row and the KB call on confirmation.
- The Guard 2 site moves to `aid-specify` CHECK. The ledger schema, the legacy rows and the
  `aid-architect` agent are updated.
- New `test-specify.sh` (SP-01 to SP-08), added to `SUITES`. The shared exempt list gains the
  `shortcut-engine.md` SP-08 row.

**Out of scope:** `aid-plan` reading the unsplit shape (delivery-008). This leaves the gap the spec
accepts in Feature 005's § 2: "No release carries that gap, since every feature ships in v4.0.0".

**Waves:**
1. Re-run the spec's stated `aid-define` re-pointing sites and reconcile the edit list.
2. The templates, the writer's `--review` and `"Effort Check"`, and `slice-requirements.sh`. Each comes with its asserting suites, for example `test-work-state-template.sh`, `test-slice-requirements.sh` and `test_feature009.py`.
3. `aid-specify` and its references, the `skill-steps.md` rows, `reviewer-dispatch.md`, the ledger schema and the legacy rows. Each task updates the suites F005 § 7 lists for its file, for example `test-scoped-review-cycles.sh` and `test-ticket-retirement-structural.sh`. These need wave 2.
4. Retire `aid-define` with the suites that name it, re-point, and update the KB.
5. The new `test-specify.sh`, the delivery's sample files and the deferred-list rows for the samples that now run. Then the delivery's resync step.

**Gate Criteria:**
- [ ] `test-specify.sh` SP-01 to SP-08 pass:
  - `aid-define` and `templates/specs/` are absent;
  - the template has `## 1.` to `## 10.`, both forms of § 11, and a `**Serves:**` line;
  - the step table is complete;
  - `check.md` names fix, accept and keep reviewing, and the `Accepted` status.
  (AC-16, AC-44)
- [ ] `effort-check.md` has a row for each of Claude Code, Codex, Cursor, Antigravity and Copilot CLI, and states the "cannot be read" path. No file under `aid-kb-build/` cites it. (AC-12)
- [ ] `test-slice-requirements.sh` prints `## 11. Technical Specification` for an unsplit document, and its output for a split document is unchanged. The writer appends a work `reviews` entry, and exits 4 on a bad grade. (AC-44)
- [ ] Samples `005-01` to `005-10` each pass 3 of 3, and so do `002-06`, `002-11`, `002-12`, `003-06`, `003-08`, `003-09` and `004-10`. `001-08` and `001-09` pass again. (AC-7, AC-9, AC-10, AC-12, AC-14, AC-15, AC-16, AC-17, AC-18, AC-28, AC-35, AC-37, AC-38, AC-44)
- [ ] G0 passes.

### delivery-008: The plan as a generated checklist on one state file
- **What it delivers:** One `/aid-plan` breaks requirements into atomic tasks grouped into deliveries, keeps `PLAN.md` as a checklist generated from the task files and the work's single `STATE.yml`, and revises the plan on request; no delivery or task state file remains; existing works migrate to the single layout, `ticket_ref` becoming `sources:`.
- **Features:** feature-006-planning
- **Depends on:** delivery-007
- **Priority:** Must

**Objective:** Deliver the Planning phase and the single work layout, plan and detail merged. This is
also the delivery at which this work migrates its own state to the single layout (Q111, Q119; see
Toolchain and Branching).

**Scope:**
- `aid-plan` is rewritten with the steps START, BREAKDOWN, CHECK, APPROVE, FINISH and REVISE.
  `aid-detail`, the delivery and task state templates and `delivery-plans/` are deleted. (AC-19)
- New `plan-template.md`; `task-detail-template.md` is rewritten. `derive-waves.sh --plan`. The
  writer gets the single layout, `--plan-sync`, the re-render and exit 11, plus the fork. (AC-19)
- The gate's legacy block is removed and replaced by the old-layout check. The allocation points pass
  `--depth`. `shortcut-engine.md` PLAN and DETAIL use `--plan-sync`. `aid-deploy` reads
  `deliveries`.
- The format-6 work-state step in `bin/aid` and `bin/aid.ps1`, byte-identical, with a
  `Test-AidInstaller.ps1` case. (AC-19)
- The dashboard reads one layout and diagnoses an old one. It shows the depth badge and the path line.
- New `test-plan.sh` (PL-01 to PL-07) and `test-work-state-migration.sh`, added to `SUITES`. The shared
  exempt list gains the `aid-execute` PL-04 row and the PL-06 mark.

**Out of scope:** `aid-execute` reading the single layout (delivery-009, Q114).

**Waves:**
1. Re-run the spec's stated searches for `aid-detail`, the deleted templates, `deliveries/delivery-NNN/` paths and per-task `STATE.yml`, and reconcile the edit list.
2. The templates, the writer's single layout and `--plan-sync`, `derive-waves.sh --plan` and `slice-requirements.sh`. Each task updates the suites F006 § 8 lists for its file, for example `test-writeback-state.sh`, `test-derive-waves.sh`, `test-task-state-transitions.sh` and `test-producer-completeness.sh`.
3. Two independent groups that both need wave 2, each with its asserting suites. First, `aid-plan` and its references, with the gate, allocation, engine, `aid-deploy` and `aid-architect` edits. Second, the dashboard's one-layout reading with the reader, server and parity suites.
4. The format-6 work-state step: bash, then its PowerShell twin, with fixtures written first and the `Test-AidInstaller.ps1` case. It needs the final single layout.
5. Retire `aid-detail` with the suites that name it, and re-point. Then the new `test-plan.sh` and `test-work-state-migration.sh` and the delivery's sample files. Then the delivery's resync step: its `aid update` migrates this work's own state.

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
- [ ] `test-work-state-migration.sh` passes on nested, old lite and single-layout fixtures, with bash and PowerShell byte-identical and a second run changing nothing. It also passes F006 § 9's fixture for a nested work that also carries the flattened delivery keys (Q129), the shape this work has. The `Test-AidInstaller.ps1` case passes under `pwsh` and 5.1. After the resync, this work's own state shows the migration on disk:
  - `.aid/works/work-003-full-aid-restructure/` has no `deliveries/delivery-*/STATE.yml`;
  - every task has `tasks/task-NNN/DETAIL.md` and a `tasks_lifecycle` entry;
  - `derive-waves.sh --plan --check` exits 0 on its `PLAN.md`.
  (AC-19, AC-25)
- [ ] Samples `006-01` to `006-05`, `006-07`, `006-08` and `005-13` each pass 3 of 3. `005-07` runs through Planning, and `001-07` passes again. (AC-7, AC-10, AC-15, AC-19, AC-21, AC-28, AC-37, AC-44)
- [ ] G0 passes.

**Notes:**
- This delivery is built directly by the main conversation, like every delivery up to 009 (Q127),
  which also covers Q119.
  - Every task of this delivery reaches its terminal state in its per-task state file before the
    delivery's resync step. That step is no task (The resync rule).
  - The resync's migration then moves those states into `tasks_lifecycle`.
- This work's `STATE.yml` is nested and also carries the template's flattened delivery keys. F006 § 8
  (Q129) makes the nested data win and drops those keys, and F006 § 9 adds the fixture.
- The delivery verification's grade is recorded with `writeback-state.sh --delivery-id 008
  --gate-field` before the resync. The migration carries it into `deliveries.delivery-008`, and
  delivery-009's format-6 building step carries it into `verify`.

### delivery-009: Building tested, verified and simplified, one task at a time
- **What it delivers:** One `/aid-execute` builds the whole plan one task at a time on the work's one branch -- build, test, verify, simplify once, re-verify only when the simplification changed something -- with a full-suite baseline, the confirmation before building, and approval stops only at milestones and real blockers.
- **Features:** feature-007-building
- **Depends on:** delivery-008
- **Priority:** Must

**Objective:** Deliver the Building phase on the single layout.

- Q114 set this delivery to be built by the main conversation directly, task by task, and Q127
  extends that to every delivery up to here (see Toolchain and Branching).
- It ends with the switch of this work onto the new `/aid-execute`.

**Scope:**
- **The skill:** `aid-execute` is rewritten with the steps START, BUILD, TEST, VERIFY, SIMPLIFY,
  REVERIFY, NEXT, DELIVERY, FINAL, MILESTONE and FINISH. Thirteen references are created, seven are
  deleted, and `task-type-rules.md` is edited. (AC-26, AC-32, AC-33)
  - The full suite's command is resolved once, at the baseline, and recorded in `full_suite.command`.
    FINAL, each re-run after a fix round and a correction call's run use the recorded command, never a
    fresh lookup; a missing one is resolved and recorded first (F007 § 4, Full suite; Q132).
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
- **The `rules.md` tracking line:** "`In Progress` at the start of EXECUTE" is reworded to name BUILD
  (`F007 › 6. Risks`, tracked with KI-001). The summary bullet is unchanged.
- **Format 6:** the building part, in bash and PowerShell, with a `Test-AidInstaller.ps1` case. The
  dashboard reads the building fields.
- **Suites:** new `test-execute.sh` (EX-01 to EX-08) and `test-simplify-guard.sh`, added to `SUITES`.
  The `aid-execute` PL-04 row leaves the shared exempt list.
- **The switch, after the resync** (Toolchain and Branching, The switch questions):
  - this work's type is recorded as `change` (Q124). This completes the record that delivery-008's
    migration filled with `aid-execute` at `START`;
  - deliveries 001-009 get their `verify` and `commit` (Q123);
  - one approval covers their milestones and the confirmation before building (Q123).

**Out of scope:** The pull-request calls made at milestones, which need delivery-010. Until then, the
close runs through `/aid-orchestrate`.

**Waves:**
1. Re-run the spec's stated search (`state-execute.md|...|delivery-issues.md` over `tests` and `dashboard`) and the re-pointing sites, and reconcile the edit list.
2. The writer's building part with its fork and parity case, `simplify-guard.sh`, `derive-waves.sh --delivery`, and the work-state template. Each comes with its asserting suites, for example `test-writeback-state.sh`, `test-derive-waves.sh` and `test-work-state-template.sh`.
3. `aid-execute` and its references, `complexity-score.sh` and `compute-block-radius.sh`, `skill-steps.md`, the shortcut engine's APPROVAL-HALT, `aid-plan` `revise.md`, `aid-developer` and the `rules.md` tracking line. Each task updates the suites F007 § 7 lists for its file, for example `test-pipeline-status-walkthrough.sh`, `test-ticket-retirement-structural.sh` and `test-compute-block-radius.sh`. These need wave 2.
4. The format-6 building step (bash, PowerShell, the `Test-AidInstaller.ps1` case) and the dashboard's building fields. These need the template. Then the re-pointing.
5. The new `test-execute.sh` and `test-simplify-guard.sh`, the delivery's sample files and the deferred-list rows for the samples that now run. Then the delivery's resync step, which installs the new `/aid-execute` and migrates this work's building fields. Then, in a new session, the gate and the switch.

**Gate Criteria:**
- [ ] `test-execute.sh` EX-01 to EX-08 pass:
  - the step table is complete;
  - no file under `aid-execute/` or `scripts/execute/` creates a branch or worktree, or names
    `run_in_background`, `max_parallel_tasks` or "merge to main";
  - `next.md` routes by states plus commits;
  - `start.md` and `final.md` name `full_suite.command` (Q132).
  (AC-26, AC-32, AC-34)
- [ ] `test-simplify-guard.sh` passes with git and without git. `test-writeback-state.sh` derives each of the seven delivery states, identical in the canonical writer and the dashboard fork. `test-never-merges.sh` passes with NM-04's exemption gone. The `Test-AidInstaller.ps1` building-step case passes under `pwsh` and 5.1. (AC-25, AC-33, AC-34)
- [ ] `canonical/aid/rules.md` § Tracking discipline names BUILD, not EXECUTE, for the `In Progress` write. (KI-001 follow-up)
- [ ] Samples `007-01` to `007-12` each pass 3 of 3, and so do `002-07`, `002-08`, `002-09`, `002-13`, `003-07`, `003-10`, `004-11`, `004-12`, `005-11`, `005-12` and `006-06`. `001-07`, `001-16` and `006-01` pass again. (AC-7, AC-9, AC-10, AC-14, AC-15, AC-17, AC-18, AC-19, AC-21, AC-26, AC-28, AC-32, AC-33, AC-34, AC-37, AC-38, AC-39)
- [ ] After the switch, four things hold:
  - `writeback-state.sh --check` exits 0 on this work;
  - `intent.reading: change`;
  - `active_skill: aid-execute` and `step: START`;
  - `qa` holds one `Approval` entry answered yes, with a `commit`, whose `covers` names
    `delivery delivery-001` to `delivery delivery-009` and `confirmation before building`.
  (Toolchain and Branching, The switch questions)
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
- **Suites:**
  - new `test-monitor-pipeline.sh` (MP-01 to MP-05), `test-push-approved.sh`, `test-merge-parent.sh`
    and `test-close-work.sh`, added to `SUITES`;
  - the `gh`/`glab` stand-ins;
  - NM-01 is narrowed, NM-03 loses its exemptions, and NM-05 and NM-06 are added, with their
    instruction-only allowances (F008 § 8).

**Out of scope:** The live-host run (`008-15`), which is part of the integration run in delivery-014.

**Waves:**
1. Re-run the spec's stated re-pointing sites (`housekeep/cleanup-classify.sh`, `origin/master`, the interim close, every `git push`) and reconcile the edit list.
2. The three new scripts and the moved `cleanup-classify.sh`, the writer's `--pull-request`, the template, the settings and the stand-ins. The moved script goes together with the housekeep classify, deletion-split and work-folder-safety suites that follow it.
3. `aid-monitor-pipeline` and its references, the gate row, `skill-steps.md`, the finishing skills, `aid-operator`, `consumption-protocol.md`, and the `milestone.md` and `finish.md` edits. Each comes with its asserting suites. These need wave 2.
4. `delete-pipeline.sh` with `test-delete-pipeline.sh` in the same task. Then the dashboard CI card and the re-pointing.
5. The new suites, the narrowed and extended NM groups, and the delivery's sample files. Then the delivery's resync step.

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
- [ ] `test-merge-parent.sh` and `test-close-work.sh` pass:
  - `merge-parent.sh start` refuses on the parent branch;
  - `merged` deletes the local branch and the worktree and keeps the remote branch;
  - a branch with an unpushed commit is kept;
  - each `work_folders` setting behaves as specified.
  (AC-11, AC-36)
- [ ] Samples `008-01` to `008-14` and `008-16` to `008-18` each pass 3 of 3, and `002-10`, `007-13` and `001-16` pass. (AC-11, AC-13, AC-14, AC-27, AC-28, AC-32, AC-35, AC-36, AC-42)
- [ ] G0 passes.

### delivery-011: Action skills and one catalog of kinds (Feature 009a)
- **What it delivers:** Seven action skills -- `/aid-create`, `/aid-update`, `/aid-fix`, `/aid-refactor`, `/aid-document`, `/aid-test`, `/aid-prototype` -- each starting from one shared START, reading a kind typed or said in plain words from the one shipped kind catalog; `/aid-test` and `/aid-prototype` run as investigations that land nothing in the project.
- **Features:** feature-009-one-skill-per-need (part a: action skills and the kind catalog)
- **Depends on:** delivery-010
- **Priority:** Must

**Objective:** Add the action layer and the catalog every phase skill reads. Nothing is retired here
yet, so the old wrapper skills keep working beside the new ones until delivery-012 removes them.

**Scope:**
- **Generated skills to hand-authored:** `aid-create`, `aid-update`, `aid-fix` and `aid-refactor`
  become hand-authored, and their four rows leave `shortcut-catalog.yml` (Q121; Notes).
- **The three rewritten skills:** `aid-document`, `aid-test` and `aid-prototype` are rewritten, with
  their references.
- **START and the catalog:**
  - new `action-start.md`;
  - `kind-catalog.yml` v2 with `actions`, the new kind fields and the new kinds;
  - `check-intent.md` § The merged catalog, with the shipped catalog as its one source, cited by every
    reader. Delivery-013 adds the second source, `.aid/kinds/`.
- **Recording the kind:** writer `--kind` and the reading `investigation`; the gate forwards `--kind`;
  `intent.kind` is added to the template.
- **Catalog readers:**
  - `aid-specify` (`start.md`, `requirements.md`, `design.md`, `check.md`);
  - `aid-plan` `breakdown.md`;
  - `aid-execute` (`test.md`, `task-type-rules.md`, the brief);
  - `aid-brainstorm` `start.md`.
- **Findings and close:** `aid-fix` `references/findings.md`. The close moves the test ledger and the
  prototype folder to the main folder. (AC-14, AC-36)
- **Skill guide and suites:**
  - the skill guide gains one line per action skill (the `<kind>` lines stay until delivery-012);
  - `test-actions.sh` group A, added to `SUITES`: AS-03 for the shipped catalog without its `domain`
    and reserved-field clauses; AS-04 without its `aid-deploy`/`aid-monitor` clause; AS-05; AS-06 for
    the findings half; AS-09 without its `.aid/kinds/`, skip-rule and review/research/report clauses.

**Out of scope:**
- The ticket kind and the retirements (delivery-012).
- Delivery-013 (Q113 part (c)):
  - the rename;
  - domain readiness: `.aid/kinds/`, the `domain` field, and the kind hooks of review, research and report.
- AC-20 and AC-30 complete at delivery-012.

**Waves:**
1. Re-run the spec's stated searches over the files this part rewrites (the second search in Feature 009 § 8), and reconcile the edit list.
2. `kind-catalog.yml` v2, `check-intent.md` § The merged catalog, writer `--kind` and `investigation`, the gate's `--kind` and the template. Each comes with its asserting suites, for example `test-idea-shaping.sh` ID-04 and `test-writeback-state.sh`.
3. `action-start.md` and the seven action skills, which need wave 2. Removing the four generated skills' rows from the shortcut catalog belongs to the same task that makes those four skills hand-authored, together with the suites that count catalog rows or doorways (`test-deploy-monitor-repurpose.sh` DMR30-DMR35, `test-shortcut-builder-invariants.sh`, `test-catalog-dirs-parity.sh`, the site's skill-count tests, `test-doc-counts.sh`). The rewrite of `aid-test` and `aid-prototype` comes with `test-work-initiation-gate.sh` Group G and its reconciliation group (Q106).
4. The catalog readers in the phase and supporting skills, the close moves (with `test-close-work.sh` and the `cleanup-classify.sh` suites), and the skill guide (with `test-skill-guide.sh`). These need the skills of wave 3.
5. The new group A and the new unit cases, and the delivery's sample files. Then the delivery's resync step.

**Gate Criteria:**
- [ ] `test-actions.sh` group A passes:
  - every action names an existing skill and an accepted reading;
  - every kind has a unique `kind`, an `about` and a `taken_by` naming existing skills;
  - no KB kind is taken by `create` or `update`;
  - every action skill cites `action-start.md`, the catalog, `skill-steps.md` and
    `question-protocol.md`;
  - every catalog reader cites its field.
  (Feature 009 § 3 The catalog)
- [ ] `build-shortcut-skills.py --check` passes with the four rows removed. None of `aid-create`, `aid-update`, `aid-fix` and `aid-refactor` carries the `GENERATED` marker. (Q121)
- [ ] `test-writeback-state.sh` passes for `--kind` and `--reading investigation`. (Feature 009 § 4)
- [ ] Samples `009-03`, `009-04`, `009-05`, `009-13` and `009-17` each pass 3 of 3, and the typed runs of `009-01`, `009-02` and `009-07` pass 3 of 3. (AC-5, AC-14, AC-15, AC-28, AC-36; their AC-30 checks complete at delivery-012)
- [ ] G0 passes.

**Notes:**
- Part (a) holds exactly what Q113 gives it -- the action skills and the kind catalog -- plus the two
  adjustments below. Everything that is domain readiness is in delivery-013.
- **Q121 keeps two adjustments of Q113's part (a):**
  - The four action skills generated from `shortcut-catalog.yml` rows become hand-authored here, so
    their rows leave the catalog, and the suites counting rows or doorways are re-recorded in the
    same task.
  - The plain-word runs of `009-01`, `009-02` and `009-07`, and the plain-only samples `009-06`,
    `009-08`, `009-09` and `009-10`, run at delivery-012. Until the wrappers retire, a plain request
    such as "create an API endpoint for orders" fits both `/aid-create` and `/aid-create-api`.

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
  `connectors/ticket-create.md` and `ticket-update.md`.
- **Free-form text:** `aid-deploy` and `aid-monitor` Step 0 hand free-form text to the intake.
- **No impediment file:** `aid-research`, `aid-review` and `aid-report` use the per-row choice.
- **Format 6:** the doorway rows (`intent.kind`, the record fill, the type), with
  `legacy-skill-names` markers in `bin/aid` and `bin/aid.ps1` and a `Test-AidInstaller.ps1` case. The
  dashboard maps sit inside markers. (AC-31)
- **Site:** the generator rewrite, the retired flows and pages deleted, the pages regenerated. (AC-31)
- **Skill guide:** the `<kind>` lines go, and SG-02 has no expansion. (AC-31)
- **Suites:** the retired and rewritten suites from Feature 009 § 8, each in the task that changes its
  file (Q106).
- **Lists:**
  - the shared exempt list loses its `shortcut-engine.md` row and ends empty;
  - the Feature 009 `skill:` rows leave `deferred.tsv`.
- **Re-pointing** applies to every retired name except `aid-config`.
- `test-actions.sh` group B: AS-01 without its `aid-configure` clause, AS-02 and AS-07 without
  `aid-config`, AS-04's `aid-deploy`/`aid-monitor` clause, AS-06's ticket half, AS-08.

**Out of scope:** The `aid-config` rename (delivery-013).

**Waves:**
1. Re-run the spec's stated suite searches (both `git grep` commands of Feature 009 § 8) and the re-pointing sites, and reconcile the edit list.
2. What replaces the engine, the ticket skills and `IMPEDIMENT.md`, each with its asserting suites:
   - the ticket procedures and the TICKET step, with `test-ticket-skills-structural.sh` and `test-ticket-retirement-structural.sh`;
   - the `aid-deploy` and `aid-monitor` Step 0 edit, with DMR20a-c of `test-deploy-monitor-repurpose.sh` and G6 of `test-downstream-worktree-entry.sh`;
   - the per-row choice in research, review and report;
   - the site generator rewritten to read `canonical/skills/`, with its `__tests__`.
   These come before the deletions.
3. The deletions. Each task deletes a file together with every suite that asserts it, retiring, rewriting or re-pointing it as F009 § 8 lists, and regenerates the site pages:
   - the wrapper skills;
   - the engine;
   - the shortcut catalog, with the remaining DMR checks and the family-scaffold suites;
   - the scaffolding;
   - `feedback-artifacts/`;
   - the builder.
4. The format-6 doorway rows, with `test-work-state-migration.sh` and the `Test-AidInstaller.ps1` case. Then the dashboard markers, with the parity test of the two legacy maps. These need the deletions.
5. The new group B and the delivery's sample files. Then the delivery's resync step.

**Gate Criteria:**
- [ ] `test-actions.sh` group B passes, and group A still passes:
  - no folder matches `aid-(create|update|design|document|test|prototype)-`;
  - no engine, shortcut catalog, scaffolding, `IMPEDIMENT.md` or builder exists;
  - no retired name appears outside the exemptions and `legacy-skill-names` markers;
  - the skill guide has no `<kind>` placeholder.
  (AC-20, AC-31)
- [ ] The site `npm test` passes on the rewritten generator. `site/scripts/gen-skills.mjs` regenerates the pages with no retired skill. (AC-31)
- [ ] `test-work-state-migration.sh` maps old doorway works as specified, and the `Test-AidInstaller.ps1` case passes under `pwsh` and 5.1:
  - an `aid-create-api` work at `Specify` reaches `/aid-specify` with `kind: api`;
  - an `aid-test-security` work reaches `/aid-test` with type investigation;
  - every row naming a retired skill sits inside the markers;
  - bash and PowerShell are byte-identical.
  (AC-25, AC-31)
- [ ] The plain-word runs of `009-01`, `009-02` and `009-07`, and the samples `009-06`, `009-08`, `009-09`, `009-10`, `009-14` and `009-16`, each pass 3 of 3. `001-01`, `001-07`, `003-02` and `008-14` pass again. `skill-steps-exempt.tsv` is empty. (AC-1, AC-7, AC-10, AC-14, AC-21, AC-28, AC-30, AC-36, AC-37, AC-43)
- [ ] G0 passes.

### delivery-013: `/aid-configure` and room beyond software (Feature 009c)
- **What it delivers:** `/aid-config` becomes `/aid-configure`, so every skill name is a verb; the catalog's kinds carry a `domain` (all `software`) and reserve the fields later works will use; the action layer names no software term; every file that says what AID is says "software first, not software only"; the roadmap records the later "Beyond software" works.
- **Features:** feature-009-one-skill-per-need (part c: the rename and domain readiness)
- **Depends on:** delivery-012
- **Priority:** Must

**Objective:** Finish Feature 009's product changes.

- The rename every earlier feature named `aid-config` for.
- Domain readiness, all of it (Q113 part (c), Q108-Q110).

**Scope:**
- **The rename:** `aid-config` becomes `aid-configure`. It covers every mention of `aid-config`:
  - the settings rows edited by Features 004 and 008, and `settings.yml`'s "Managed by" line;
  - `bin/aid` and `bin/aid.ps1`, whose "Run" line stays byte-identical across the two;
  - the dashboard comments;
  - sample `002-02`'s `skills:` line.
  (AC-22, AC-31)
- **The user's own kinds:** `check-intent.md` § The merged catalog gains its second source, each
  `*.yml` in `.aid/kinds/` read after the shipped file in name order. It also gains:
  - the additive-only precedence;
  - the skip rule with its one notice line per skipped entry.
  `test-shared-prune.sh` and `test-shared-remove.sh` keep a file under `.aid/kinds/` unchanged after
  `aid update` and `aid remove`. (Q109)
- **Any skill may take a kind:** `aid-review`, `aid-research` and `aid-report` each call the kind hook
  with their own name, pass the result to the gate as `--kind`, and read that kind's `ask` and
  `checks`. (Q109)
- **Catalog fields:** `domain: software` on every shipped kind, and the reserved fields `risk`,
  `limits`, `sign_off` and `release` set on none.
- **Wording:** the action layer is worded with no software term (AS-10).
- **Identity statement:** "software first, not software only" in every file the identity search
  finds, except the files under `docs/` and `site/src/content/docs/`, which the final pass rewrites.
  `decisions.md` records Q108. `roadmap.md` § Later gains "Beyond software" (Q110).
- **Samples:** `009-18-budget-sheet-no-repository` and `009-19-user-kind-for-review`.
- **Lists:** `test-actions.sh` group C:
  - AS-01's `aid-configure` clause;
  - AS-02 and AS-07 for `aid-config`;
  - AS-03's `domain`, reserved-field and user-file clauses;
  - AS-09's `.aid/kinds/`, skip-rule and review/research/report clauses;
  - AS-10.
  The description exempt list ends empty.

**Out of scope:** The user documentation (delivery-014).

**Waves:**
1. Re-run the identity search of Feature 009 § 5 and a search for `aid-config`, and reconcile the edit list.
2. Five groups that do not depend on each other, each with the suites asserting the text it changes:
   - the rename, with the `aid-config` comments the F009 § 8 list keeps or changes;
   - the catalog's `domain` field;
   - the action-layer wording;
   - the identity statement;
   - § The merged catalog's second source and skip rule, with the `.aid/kinds/` cases.
3. The kind hooks of `aid-review`, `aid-research` and `aid-report`, which need the merged catalog.
4. The new group C and the delivery's sample files. Then the delivery's resync step.

**Gate Criteria:**
- [ ] `test-actions.sh` group C passes, and groups A and B still pass:
  - `aid-configure` exists and `aid-config` does not;
  - `aid-config` is named nowhere outside the exemptions;
  - every shipped kind has `domain: software` and no reserved field;
  - the action layer has none of the AS-10 terms;
  - § The merged catalog names `.aid/kinds/`, the shipped-first order and each skip case with its
    notice line;
  - review, research and report call the kind hook with their own name and pass `--kind`.
  (AC-22, AC-31; Q109)
- [ ] `test-shared-prune.sh` and `test-shared-remove.sh` keep a file under `.aid/kinds/` unchanged after `aid update` and `aid remove`. (Q109)
- [ ] Samples `009-15`, `009-18` and `009-19` each pass 3 of 3, and `002-02` passes on `/aid-configure`. (AC-8, AC-14, AC-22, AC-28, AC-30, AC-36)
- [ ] Run without the release flag, the identity search of Feature 009 § 5 finds "software first, not software only" in every file outside `docs/` and `site/src/content/docs/`. The description exempt list of `test-skill-guide.sh` is empty. (Q108, NFR-T)
- [ ] G0 passes.

### delivery-014: Final documentation pass and release readiness
- **What it delivers:** The user documentation describes the finished product -- the phases, the skills, the old -> new table -- and every release check passes with all lists empty and the full integration suite green, so the work is ready for the v4.0.0 pull request.
- **Features:** feature-009-one-skill-per-need (final documentation pass, AC-45; Q104)
- **Depends on:** delivery-013
- **Priority:** Must

**Objective:** Run AC-45's one documentation pass. The criterion places it
"After all features are built", so it can only be judged against the finished product. Then run the
end-of-work checks that make the branch releasable.

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
2. `retired-names.txt` and `test-doc-names.sh`. Then the documentation rewrite and the site regeneration, each with `test-doc-counts.sh` and the site checks in the same task.
3. The delivery's resync step. The release checks under `AID_RELEASE_CHECK=1` and the full integration suite are gate checks, run after it (The resync rule).

**Gate Criteria:**
- [ ] With `AID_RELEASE_CHECK=1`, DN-01, DN-02 and DN-03 pass:
  - no file under `docs/`, `site/src/content/` or `examples/`, nor `README.md`, names a retired skill
    or an old phase name outside the markers;
  - every name in `retired-names.txt` has a row in `backlog.md` § Next Release.
  (AC-24, AC-45)
- [ ] With `AID_RELEASE_CHECK=1`, DT-02 and both exempt-list release checks pass, with `deferred.tsv` and both exempt lists empty. The shared list's check is F002 § 8; the description list's is SG-04. (NFR-T)
- [ ] The full integration suite passes. Every sample under `tests/conversation/samples/` passes 3 of 3, including `008-15`, `009-11` and `009-12`. (Every AC a sample's `covers` names)
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

- `run_generator.py` renders `profiles/`. Then it always resyncs the dogfood install through
  `sync_dogfood.py`, which runs `aid update --from-bundle` on the tree it runs in. The script has no
  opt-out flag.
- `tests/canonical/test-dogfood-byte-identity.sh` requires the installed trees to equal
  `canonical/`.

So every delivery that passes G0 replaces the skills and scripts installed in this repository. From
delivery-005 on, it also runs format-6 migrations over this work's own state. The rules below keep
that from happening in the middle of a delivery.

**Planning (Q111).** Once this plan is approved, today's `/aid-detail` writes the task files of all 14
deliveries up front. Its FIRST-RUN covers every delivery and its task numbering is global, so the
later migration of this work meets no duplicate task id.

- Every delivery's first wave re-runs its spec's stated searches.
- From delivery-009 on, any change to a later delivery's tasks goes through the new `/aid-plan`
  REVISE.

**Who builds (Q127).**

- **Deliveries 001-009 are built directly by the main conversation** (Q114 for 009, Q127 for all of
  them). Today's `/aid-execute` is never used for this work.
- **Deliveries 010-014 are built by the new `/aid-execute`**, which delivery-009 installs.
- Every task works in the `work-003` worktree and commits on `work-003` (Q112). No task creates a
  branch or a worktree, or merges anything.
- **Moot under Q127:**
  - the patches to today's `/aid-execute` (skipping Check 5 and "merge to main");
  - `execution.max_parallel_tasks` (Q118);
  - the per-task worktrees (Q120);
  - Q119 (the main conversation running delivery-008's resync and gate), now the general rule.
  Q112 still holds.

**The resync rule.** It holds for every delivery, whichever builder runs it.

- In the live work tree, `run_generator.py` runs only as a delivery's resync. The resync renders
  `profiles/`, verifies, and resyncs the installed trees, all at once.
- A **resync-relevant change** is a change to a file the resync renders or installs: anything under
  `canonical/`, `bin/` or `lib/`, which `run_generator.py` renders and `release.sh --stage-only`
  stages for `aid update`.
- These are not resync-relevant: state writes into the work folder through the writer, and commits
  under `.aid/knowledge/` (the KB is not installed).

1. **The resync is a delivery step, never a task.** No task file holds it, and no build step of any
   builder runs it. The main conversation runs it, in a session of its own, at the point where the
   delivery's resync-relevant changes are final:
   - deliveries 001-009: after the delivery verification and its fix rounds (step 3 below);
   - deliveries 010-014: when the new `/aid-execute` pauses at the delivery's MILESTONE approval
     question (see "How deliveries 010-014 are built").
   The resync is committed alone, as `delivery-NNN: resync`, and the session ends.
2. **The gate runs in a new session**, from the freshly installed skills, on a tree whose last
   resync-relevant change is that resync. No skill text loaded before the resync is acted on. The gate
   covers the stanza's criteria, the samples and G0.
3. **A resync-relevant change after a resync** starts the cycle again: another resync in its own
   session, then the gate in a new one. Such a change can be a fix the gate asks for, or a change the
   maintainer asks for at the milestone.
4. **Why this cannot loop.** A resync starts no work.
   - F007 judges a result stale only "when a `Done` task in their scope has a commit they do not
     contain" (F007 § 2 step 7). NEXT's KB check reads only a task's commits.
   - The resync commit is no task's commit, so it makes no `verify`, `full_suite` or approval stale,
     and routes nothing.
   - The cycle repeats only when the gate fails or the maintainer asks a change, and each repetition
     builds that fix.
   - It ends at the first resync whose gate passes and whose approval is answered yes.
5. A task that edits an agent does not run the generator. Its render reaches `profiles/` at the
   resync. Tasks test as the intro's "Testing before the resync" says.
6. **Files the resync changes are regenerated after it, in the gate session, before the gate's
   checks.** Any generated or derived file that the resync itself changes -- `INDEX.md` and `kb.html`
   after a KB conversion, the site reference pages (`gen:reference`, for example `reference/settings.md`
   after a format re-stamp), the plan render after the work-state migration -- is regenerated with the
   installed scripts as a listed step that is not a task, then the site `npm test` runs. Each delivery's
   task files list these steps; they are not resync-relevant.

**How deliveries 001-009 are built (Q127, Q125).** The main conversation drives each delivery. It
writes every state change through `writeback-state.sh` the moment it happens, with `AID_STATE_FILE`
and `AID_WORK_DIR` exported for this work (tech-debt W5-5).

1. **Start.**
   - For delivery-001 only, write `--pipeline --field Phase --value Execute` and
     `--field "Active Skill" --value aid-execute`. Delivery-008's migration reads that phase to fill
     this work's record with `/aid-execute` at `START`; the readers show it as Building from
     delivery-002 on.
   - For every delivery, write `--delivery-id NNN --lifecycle Executing`.
2. **Each task, in wave order, one at a time:**
   1. Write `In Progress` with `--task-id NNN --field State` (plus `--delivery-id NNN` while the layout is
      nested), and commit the file holding the task's state alone, as `task-NNN: In Progress`.
   2. Dispatch the executor for the task's type (`aid-developer`; `aid-researcher`, `aid-architect` or
      `aid-tech-writer` by type), in a clean context, tiered by `agent-dispatch-tiering.md`. It gets the
      task file, its requirements slice (the task's `### Feature NNN` section, from its heading to the next, read so that headings inside fenced code blocks do not count, plus the §1-§10 entries the task cites; today's `slice-requirements.sh` is not used for this, because this document's fenced example headings end § 11 early), the KB documents the index routes to, the same-task rule and
      this instruction: "work in the `work-003` worktree only; create no branch or worktree; do not run
      `run_generator.py`". It returns its changes and its test command; it never asks the user.
   3. Run the task's tests ("Testing before the resync").
   4. Write `In Review`, and commit the state file alone, as `task-NNN: In Review`.
   5. Dispatch `aid-reviewer` in a clean context, at a tier no lower than the executor's. Grade its
      7-column ledger with `grade.sh`, and write the grade with `--task-id NNN --field Review`. From
      delivery-008 on, also record it with `--review --grade G --notes 'task-NNN verify; ...'`.
   6. Fix rounds by the executor, scoped to the failing tests or rows, then the tests and the review
      again. The same failure after three rounds is raised to the maintainer.
   7. Write `Done`, or `Failed`. That state goes into the task's own commit on `work-003`.
3. **Delivery verification.**
   - Write `--lifecycle Gated`.
   - One `aid-reviewer` pass over the delivery's diff from its first task's base, graded. Fix rounds
     follow as in step 2.6.
   - Record the grade with `--gate-field Grade`. Every delivery's verification runs before its own
     resync, so this mode is still installed, up to and including delivery-009. The format-6 building
     step that delivery-009's resync runs carries every delivery's gate grade into its `verify`.
4. **The resync** (resync rule 1). Then the session ends.
5. **The gate, in a new session** (resync rule 2).
   - A gate failure is fixed as a fix round of step 3, then the delivery goes back to step 4.
   - When the gate passes, write `--lifecycle Done`.
   - For delivery-009 only, its resync installs the F007 writer, which refuses `--lifecycle`,
     `--gate-field` and `--field Review` (exit 4) and derives the delivery state itself. So a fix after
     delivery-009's resync records its grade with `--delivery-id 009 --field Verify`, and no lifecycle
     is written.

**How deliveries 010-014 are built.** The new `/aid-execute` runs the plan from its saved step,
following F007 § 2.

- Its steps run in order, all in the session that runs them:
  - every task's BUILD, TEST, VERIFY, SIMPLIFY, REVERIFY and NEXT, with NEXT's KB check;
  - then DELIVERY (verify, one simplify, a re-verify when something changed);
  - FINAL, for the last delivery;
  - MILESTONE's collect and corrections (step 10, sub-steps 1 and 2).
  These steps make every resync-relevant change of the delivery. They come before the resync, so
  none of them runs on skill text loaded before it. Every suite they run follows "Testing before the
  resync": TEST runs each copy-reading suite in a scratch copy. FINAL and each re-run after a fix round
  run the recorded `full_suite.command` (F007 § 4, Full suite), which names the driver from
  delivery-010's gate session on.
- MILESTONE's approval question is written `Pending` with `--ask` before it is shown (step 10.3).
  `ASK` then pauses the work (`lifecycle: Paused-Awaiting-Input`; F002 § 4, Steps and hand-offs,
  step 3). This is the defined point. The main conversation does not answer it, and ends the session.
- **Resync session** (resync rule 1): the resync, committed alone, then the session ends.
- **Gate session** (resync rule 2): the stanza's criteria, the samples and G0 on the head, except G0's
  lane item, which the push carries. Then the main conversation resumes `/aid-execute`, which asks the
  open approval question first.
  - **Gate passed, and the maintainer approves:** the answer is recorded with `--answer --commit
    <head>`, so the approval covers the resync commit. The push question follows (step 10.4).
  - **Gate failed, or a change asked:** the approval is answered with the change. It becomes correction
    tasks (step 10.3, How an answer is recorded), built through the task loop. DELIVERY runs again
    because `verify` is stale, and the run pauses at the milestone question again. The resync session
    and the gate session repeat (resync rule 3).
- After a yes, the KB call on confirmation (step 10.3) may commit under `.aid/knowledge/`. That is not
  resync-relevant. Its commit reaches the pull request only through its own approval at PUSH
  (F008 § 2, PUSH, Every way in).

**The switch questions.** Only these moments need the maintainer. No AID skill resumes this work
before delivery-010, so its record is not consulted until the switch.

| When | What happens | Answer |
|---|---|---|
| Delivery-001's start | The main conversation writes `phase: Execute` and `active_skill: aid-execute`. | No question. |
| After delivery-005 and delivery-006 | The KB converts to `STATE.yml`, with its questions all already answered. Baselines are back-filled. `pipeline.parent_branch` is filled with `master`. | No question. |
| Delivery-008's resync | The migration moves this work to the single layout and drops `pipeline.path`; `intent.depth` takes `full`. It fills the record from `phase: Execute`: `aid-execute` at `START`. The type is left empty (Q74). | No question. |
| Delivery-009, after its resync, in the gate's new session | The main conversation does two things. **(1)** `--check` reports the type missing. The main conversation runs `--repair --skill aid-execute --name START --reading change`, with Q124 as the maintainer's recorded confirmation. **(2)** It writes `Verify` and `Commit` for deliveries 001-009 with `--delivery-id NNN --field`. `Verify` is the gate grade each delivery recorded, which the migrations already carried; writing it confirms it. `Commit` is the head each gate passed on. Then it asks one approval (Q123): "Deliveries 001-009 are built and each passed its gate; approve them, and confirm building goes on with delivery-010?" It is recorded through `--ask` and `--answer`: `category: Approval`, `covers: delivery delivery-001; ...; delivery delivery-009; confirmation before building`, `commit` the head. | (1) none: Q124. (2) yes. |
| Delivery-010's START | `--check` passes, and the confirmation is recorded. The new `/aid-execute` asks only the wave question, and records the full-suite baseline as `not taken` (an old work). With every earlier delivery's `verify` and approval current, its routing goes straight to delivery-010's first task. No catch-up milestone, and so no push question, comes before `/aid-monitor-pipeline` exists. | "No stop per wave". |
| Delivery-010's gate session | Before resuming `/aid-execute`, the main conversation saves `full-suite.sh` in the work folder ("Testing before the resync", The driver) and commits it alone. Then it records it with `--full-suite --field Command --value 'bash .aid/works/work-003-full-aid-restructure/full-suite.sh'`. FINAL, its re-runs and a correction call's run use the recorded command, never a fresh lookup (F007 § 4, Full suite; Q132), and so does F008's run on a merged tree (F008 § 2, PARENT, step 4). Later gate sessions need no check: a command is looked up only at the baseline or when none is recorded, and from this write on one is recorded. | No question. |
| Delivery-010's milestone | The first push question, "Create or update the pull request now?". Yes opens the draft v4.0.0 pull request from `work-003` to `master` through `/aid-monitor-pipeline`. | Maintainer's choice. Yes starts G0's lane check through the milestone push. |

After delivery-014, the work reaches CI through `/aid-monitor-pipeline`, which marks the pull request
ready.

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | The pipeline building this work is the product being changed. A generator run outside a delivery's resync would change installed skills and the writer under a running delivery. From delivery-005 on, it would also migrate this work's state. | H | The resync rule: the generator runs only as a resync, after the last change, and each resync ends the session. Before a resync, every copy-reading suite runs in a scratch copy with its own repository, which no migration can follow back to the live work: a task's tests, and the full suite at FINAL and its re-runs (Testing before the resync). |
| 2 | Deliveries 001-009 are built directly. Without a building skill, the per-task state writes and reviews depend on the main conversation following the procedure, and a missed write leaves a task at `Pending` while it runs. | H | The stated procedure leaves checkable proof (Q125): two state-only commits per task, the task's review grade, and from delivery-008 a `reviews` entry. G0 checks it for every delivery 001-009. |
| 3 | The same files are edited in most deliveries: `writeback-state.sh` and its dashboard fork, `work-state-template.yml`, the twin dashboard readers, the `rules.md` skill guide, `skill-steps.md`, and `bin/aid` with `bin/aid.ps1`. | M | Strictly sequential deliveries. The same-task rule (Q106) keeps the writer, template, reader-parity and shell-parity suites green at every task. Every new state key follows the block-style rule (KI-002), checked by SS-08. |
| 4 | The task files are written up front, but earlier deliveries move and rename files that later task files name. Each spec's site lists were also measured before this work began. | M | Every delivery's first wave re-runs its spec's stated searches and reconciles the edit list. From delivery-009 on, task changes go through `/aid-plan` REVISE. |
| 5 | Format 6 is assembled across five deliveries, while this repository is migrated after each one:<br>- 005: the carriers and the KB step;<br>- 006: baselines and the parent branch;<br>- 008: work state;<br>- 009: building fields;<br>- 012: doorway rows.<br>Later steps arrive on a repository already stamped 6. The native Windows lane runs only `Test-AidInstaller.ps1` and `Test-InstallProvisioning.ps1`. | M | Each step is detection-driven and idempotent, with a fixture of a repository already at format 6. Each delivery adds its step's case to `Test-AidInstaller.ps1` (Q126), so the PowerShell twin runs natively under 5.1. Its migration suite joins the Linux `SUITES` list, where `pwsh` 7 checks byte identity. |
| 6 | Three suites are split (Q113, Q115). A group added before its part lands turns the full suite red, and an earlier group broken by a later part goes unnoticed if only the new group is run. | M | Each group is added in the delivery that lands its part. G0 runs the whole `run-all.sh`, so every earlier group runs at every gate. |
| 7 | The conversation suite is costly and noisy. It needs 3 runs of 3, an LLM judge, and Claude Code on the maintainer's machine, never CI. All 14 gates run samples, and delivery-014 re-runs every one plus the live hosts and tracker. | M | Each gate runs only its own and its re-run samples, so the final run is a re-run. `deferred.tsv` is kept current at every gate. |
| 8 | Between delivery-011 and delivery-012, a new action skill and an old wrapper both fit some plain requests. | L | Plain-word sample runs wait for delivery-012 (Q121). Typed runs gate delivery-011. |
