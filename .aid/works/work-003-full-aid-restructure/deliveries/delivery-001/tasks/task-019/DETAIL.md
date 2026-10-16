# task-019: Conversation-runner check test-conversation-runner.sh

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

**Source:** feature-001-plain-language-requests -> delivery-001 -> AC-1, AC-21, AC-29

**Depends on:** task-004, task-010

**Scope:**
- Create `tests/canonical/test-conversation-runner.sh` (Q134, D10). It is a bash harness on
  `tests/lib/assert.sh`, with `# COVERS: tests/conversation/` and a group filter (T6).
  - It drives `tests/conversation/run.py` with a stub `claude` placed first on `PATH`, built in a
    temporary folder. The stub logs its argv and answers in stream-json.
  - It builds its own named tree under its temporary folder: `samples/feature-900/`, `fixtures/stub/`
    and `briefs/` (stand-in `simulated-user.md` and `judge.md`). It passes them with `run.py`'s
    `--samples-dir`, `--fixtures-dir` and `--briefs-dir`, and reads no committed sample, fixture or
    brief.
  - It runs with `HOME` pinned and makes no network call.
- `run.py` installs AID through `tests/lib/bundle.sh`, so the suite reaches `profiles/` through
  `release.sh`. Its header says so, which places it in the driver's copy-reading set (`P`).
- This task depends on task-010 by the stanza's order (the last wave adds the unit cases). A delivery's last wave adds its unit cases
  (PLAN.md, the same-task rule bullet).
- Suites to update in this same task: none.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-001-sites.md` assigns to `task-019`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-019: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-019`.
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
- [ ] In the scratch copy, `bash tests/canonical/test-conversation-runner.sh` exits 0, with groups covering: exit 2 on a bad call; `--validate` (exit 0 and 1); the five capture files; the agent, simulated-user and judge flags; the `files.diff` exclusions; `tool-called` and `tool-not-called` checks; a Pending ledger row -> a failed run; 1 failure in 3 -> exit 1; the 12-turn cap.
- [ ] Each group fails when its behaviour is broken in a throwaway copy of `run.py` (one mutation per group, restored afterwards).
- [ ] The suite is deterministic and cleans up after itself: its temporary folders are removed and `HOME` is pinned. It needs no network and no real `claude`, and finishes inside the 300-second budget of `run-all.sh`.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
