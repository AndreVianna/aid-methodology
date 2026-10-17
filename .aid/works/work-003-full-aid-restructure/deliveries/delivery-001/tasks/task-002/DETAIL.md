# task-002: rules.md request handling, skill guide and summary bullet

> **Execution protocol (binding on whoever executes this task -- no
> exceptions):** the moment this task's `State` changes, write it --
> `In Progress` before starting work, `In Review` before dispatching the
> reviewer, and the terminal value (`Done` / `Failed`) at the end -- via
> `writeback-state.sh --field State --value ...`. This applies equally
> whether the main/orchestrator agent executes this task directly or
> dispatches it to a sub-agent; neither may skip, batch, or defer these
> writes. (`Blocked` is a distinct, orchestrator-assigned value for a
> DIFFERENT, downstream task that depends on a failed one -- it is never
> self-written by the task being executed.) Full mandate:
> `aid-execute/references/state-execute.md § MANDATORY: State-Write
> Protocol`.

**Type:** IMPLEMENT

**Source:** feature-001-plain-language-requests -> delivery-001 -> AC-1, AC-2, AC-3, AC-4, AC-5, AC-6

**Depends on:** task-001

**Scope:**
- Edit `canonical/aid/rules.md` as REQUIREMENTS.md § 11 Feature 001 `##### 1. Files and layout` and
  `##### 3. Components` say.
  - `## Handling a request` replaces `## Workflow`. Start from the spec's draft, and stay within 19 lines
    by the SG-01 counting rule: delivery-002 turns the last bullet into two lines (REQUIREMENTS.md § 11
    Feature 002 `##### 3. Question protocol`, "19 of its 20 lines"), so one line of the cap stays free.
  - Add a new `## Skill guide`:
    - one line per skill, `` - `/aid-x` -- what it is for; when to use it ``, at most 100 characters;
    - in the order phase, KB, supporting, setup;
    - each action-and-kind family as one line with a `<kind>` placeholder that expands against
      `canonical/aid/templates/shortcut-catalog.yml`;
    - naming `canonical/skills/` as this delivery leaves it: today's set, without `aid-triage`, with
      `aid-orchestrate`.
  - Add the spec's summary bullet, so the summary goes from 7 to 8 bullets.
  - Fix KI-001 in `## Tracking discipline (IMPERATIVE)`: the work state file is
    `.aid/works/work-NNN-*/STATE.yml`, and the "FULL or the LITE path" wording goes.
  - The file names no tool folder, no `canonical/` path and no extra `<!-- AID` comment.
- Suites to update in this same task:
  - `tests/canonical/test-shared-layout-sources.sh`: the assertion "rules summary block carries the seven
    bullets" becomes eight;
  - `tests/canonical/test-install-core-primitives.sh`: "summary block: seven bullets ..." becomes the new
    physical line count;
  - `tests/canonical/test-aid-cli-parity.sh` FIX-D8: `## Workflow` becomes `## Handling a request`;
  - any other suite the findings' S5 assigns here.
- **Site regeneration (G1, G5).** When this task adds, deletes, renames or edits anything under
  `canonical/skills/`, `canonical/agents/` or `canonical/aid/templates/`, it runs
  `(cd site && npm run gen:skills && npm run gen:reference)` in this same task and commits the output:
  the skill pages, `skills/index.md`, `src/data/skill-flows/`, `reference/skills.md`,
  `reference/agents.md` and `scripts/.skills-manifest.json`.
  - It also updates any hard-coded count or name list in a site generator, for example the agent count
    in `site/scripts/gen-reference.mjs`, so the generators' drift checks pass at this task's end.
  - A generated site page is never edited by hand.
- **Later checks on this task's files (G3).** Before `Done`, run by hand, over the files this task
  writes, every static-check pattern that this delivery's own suites or an earlier delivery's suites apply
  to those files, and fix every hit here. Repo-wide criteria in this file are scoped to what this task
  owns.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-001-sites.md` assigns to `task-002`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-002: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`.
     - **Work-folder-only rule.** A task whose changes all lie under `.aid/works/` runs no suite: steps 2-5
       are skipped, and the report says so. The work folder is transient pipeline state that no suite may
       depend on, and it is not resync-relevant (PLAN.md § "Testing before the resync"). `select-suites.sh`
       is not the reason and is not run for it: it selects every suite with no `# COVERS:` header, whatever
       changed.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-002`.
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
     - Run `python3 -m pytest <file>` for each dashboard test file this task changes.
  6. **Report.** For each suite, report where it ran, its result and its run count.
     - Ceiling (T5): one full run of steps 2-5 per test round. Between rounds, re-run only the failing
       group (T6).
     - The same failure after three fix rounds goes to the maintainer.

**Acceptance Criteria:**
- [ ] `awk '/^## /{p=($0=="## Handling a request")} p' canonical/aid/rules.md | awk 'NF{n=NR} END{print n}'` prints a number of at most 19, leaving the line delivery-002's two-line last bullet needs (SG-01's cap is 20). The section states each rule of the spec's draft: match by meaning; a project question starts no work; one, several or no match; a typed command wins; check the reading; `/aid-orchestrate`; show the reading; which phases run; re-route; raise KB conflicts; one topic at a time (AC-1 to AC-6).
- [ ] `sed -n '/^<!-- AID:SUMMARY:BEGIN -->$/,/^<!-- AID:SUMMARY:END -->$/p' canonical/aid/rules.md | grep -c '^- '` prints 8, and the new bullet carries the spec's wording (AC-1, AC-4).
- [ ] No guide line exceeds 100 characters (the SG-03 rule). The guide's names, with `<kind>` expanded against the catalog, equal `canonical/skills/` minus `aid-triage` plus `aid-orchestrate`, both ways (the SG-02 rule, checked by a one-off command until task-014 lands) (AC-6).
- [ ] `## Tracking discipline (IMPERATIVE)` names `.aid/works/work-NNN-*/STATE.yml`, and `grep -c 'LITE path' canonical/aid/rules.md` prints 0 (KI-001).
- [ ] `test-shared-layout-sources.sh`, `test-install-core-primitives.sh` and `test-aid-cli-parity.sh` pass in the scratch copy.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
