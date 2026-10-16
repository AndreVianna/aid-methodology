# task-014: Skill-guide static suite test-skill-guide.sh (SG-01 to SG-06)

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

**Source:** feature-001-plain-language-requests -> delivery-001 -> AC-6, AC-21, AC-23

**Depends on:** task-010

**Scope:**
- Create `tests/canonical/test-skill-guide.sh`, as REQUIREMENTS.md § 11 Feature 001 `##### 6. Testing`,
  Static check, says.
  - It is a bash harness on `tests/lib/assert.sh`, with `# COVERS:` lines for `canonical/aid/rules.md`,
    `canonical/skills/` and `canonical/agents/`.
  - Groups SG-01 to SG-06, with a group filter (T6).
  - SG-04 holds the description exempt list from the findings' S9. It fails if an exempt skill no longer
    exists, and with `AID_RELEASE_CHECK=1` it fails while the list is not empty.
  - SG-06 stages one bundle through `tests/lib/bundle.sh`, which runs `release.sh --stage-only` from
    `profiles/`, and installs it for each of the five tools.
  - The suite is copy-reading: its text names `release.sh`, `.claude/skills/` and `.agents/skills/`, so it
    runs in the scratch half.
- Suites to update in this same task: none.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-001-sites.md` assigns to `task-014`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-014: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-014`.
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
- [ ] In the scratch copy, `bash tests/canonical/test-skill-guide.sh` exits 0 and reports a PASS for each of SG-01 to SG-06.
- [ ] Each mutation fails its group, and each is restored afterwards: a 21st line in § Handling a request (SG-01); a guide line removed, or a stray skill folder added (SG-02); a 101-character guide line (SG-03); a description without "Use when", an exempt row naming a missing skill, or `AID_RELEASE_CHECK=1` with a non-empty list (SG-04); `canonical/skills/aid/` or `canonical/agents/aid-orchestrator/` created, or `canonical/agents/aid-developer/` removed (SG-05); an installed skill changed by one byte, or given `disable-model-invocation: true` (SG-06) (AC-6, AC-21, AC-23).
- [ ] SG-06 checks each of the five tools at its own skills path (`.claude/skills/` for Claude Code, `.agents/skills/` for the others), for byte identity with `canonical/`, `name` equal to the folder and a non-empty `description` (AC-21).
- [ ] The suite is deterministic and cleans up after itself: its temporary folders are removed and `HOME` is pinned. It finishes inside the 300-second budget `run-all.sh` gives each suite.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
