# task-050: test-skill-steps.sh group E and the shared exempt list

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

**Type:** TEST

**Source:** feature-002-step-by-step-decisions -> delivery-002 -> AC-37

**Depends on:** task-032, task-033, task-034, task-035, task-036, task-037, task-038, task-039, task-040, task-041, task-042, task-043, task-044

**Scope:**
- Create `tests/canonical/test-skill-steps.sh` with group E: SS-02 without its chaining-file clause,
  SS-03, SS-08, SS-11, SS-12 and SS-14, as REQUIREMENTS.md § 11 Feature 002 `##### 8. Testing` defines them. It has `# COVERS:` lines
  and a group filter.
- Create `tests/canonical/skill-steps-exempt.tsv` (`entry`, `checks`, `owner`). Its rows are the exempt
  per-skill files (SS-14) and the exempt finishers (SS-12) of the spec.
  - The list fails on an entry that no longer exists, and under `AID_RELEASE_CHECK=1` while it is not
    empty.
  - It includes `aid-design` for SS-12 only.
  - It holds one row for `canonical/aid/templates/state-machine-chaining.md` with `checks` `SS-03` and owner
    "Feature 002 sweep (delivery-003, task-074)". The file keeps its old example `**Advance:**` lines until
    task-074 deletes it, and the list's own rule (an entry that no longer exists fails) makes task-074
    remove the row with the file.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-002-sites.md` assigns to `task-050`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-050: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-050`.
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
     - The same failure after three fix rounds goes to the maintainer.

**Acceptance Criteria:**
- [ ] `bash tests/canonical/test-skill-steps.sh` passes on the tree, and reports each group.
- [ ] Each mutation fails its group in a scratch copy: a `PAUSE-FOR-USER-DECISION` line (SS-03); `phase: Execute` in a skill (SS-11); a hand-written `lifecycle: Completed` outside the list (SS-12); `initiator:` in a non-exempt skill (SS-14); a `SKILL.md` with a Dispatch table and no citation (SS-02); a flow list in a template (SS-08); an exempt row naming a missing folder; `AID_RELEASE_CHECK=1`.
- [ ] The suite is deterministic, cleans up its temporary files and finishes within the 300-second budget `run-all.sh` gives each suite.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
