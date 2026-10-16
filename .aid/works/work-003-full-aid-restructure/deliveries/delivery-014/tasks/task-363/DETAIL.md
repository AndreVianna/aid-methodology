# task-363: KB test landscape for the name check, the regenerated index and the view

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 363 --field State.

**Type:** DOCUMENT

**Source:** feature-009-one-skill-per-need -> delivery-014 -> AC-45

**Depends on:** task-355, task-362

**Scope:**
- `.aid/knowledge/test-landscape.md`: `test-doc-names.sh` and `retired-names.txt`, its lane and its place in the live
  release checks; the full integration run before release (every sample 3 of 3, `008-15`, `009-11`, `009-12`).
- Then regenerate `INDEX.md` and render `kb.html` with the installed scripts (G0).
- What this task writes under `.aid/knowledge/` is inside DN-03's identity search: it describes DN-03 without quoting
  the search's phrases, or the file also carries "software first, not software only" (G3).
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
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-014-sites.md` assigns to `task-363`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-363.base`, which `/aid-execute` BUILD records on the
  first round). Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-363`.
       That includes the copy's own `run_generator.py`, run from inside it, then the `resync` commit.
     - Delete from `"$S"/tests/canonical/` every `test-*.sh` not in `COPY`.
     - Run `(cd "$S" && HOME="$(mktemp -d)" bash tests/run-all.sh)` and record its failures.
     - Run `rm -rf "$S"` before step 4.
     - If the copy's generator fails, that failure is the result, and `COPY` is reported as not run.
  4. **Live half.**
     - When `LIVE` is every suite outside `COPY`, run `HOME="$(mktemp -d)" bash tests/run-all.sh` and
       drop the `COPY` suites' results by name.
     - Otherwise, run each `LIVE` suite with `HOME="$(mktemp -d)" bash tests/canonical/<suite>`.
  5. **Outside `run-all.sh`.**
     - Run `(cd site && npm test)` when this task changes anything under `canonical/skills/`,
       `canonical/agents/` or `canonical/aid/templates/`, or under `docs/` or `site/` (G5). Run `npm ci`
       there first if `site/node_modules` is absent.
     - Run `python3 -m pytest <file>` for each dashboard Python test file this task changes, and
       `node --test <file>` for each dashboard `.mjs` test file it changes.
  6. **Report.** For each suite, report where it ran, its result and its run count.
     - Ceiling (T5): one full run of steps 2-5 per test round. Between rounds, re-run only the failing
       group (T6).
     - The same failure after three fix rounds is a real blocker (`/aid-execute` TEST,
       `references/blocker.md`).

**Acceptance Criteria:**
- [ ] `test-landscape.md` names `test-doc-names.sh`, `retired-names.txt` and the integration run.
- [ ] With `AID_RELEASE_CHECK=1`, `test-doc-names.sh` passes where the test step puts it (the scratch copy), after this task's KB edits: DN-01 and DN-03 find nothing, the files this task writes included (G3).
- [ ] `INDEX.md` is regenerated and `render-kb-view.sh --check` exits 0; no work id, and the lints pass.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
