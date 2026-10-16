# task-009: aid-triage retired, with its site roster and tests

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

**Source:** feature-001-plain-language-requests -> delivery-001 -> AC-6

**Depends on:** task-006, task-007, task-008

**Scope:**
- Delete `canonical/skills/aid-triage/`. task-006 has already moved its heuristics into
  `check-intent.md` and `size-and-route.md`.
- Remove the triage mentions in `canonical/aid/templates/shortcut-catalog.yml`.
- In `canonical/skills/aid-describe/`, re-point the triage mentions in `SKILL.md`,
  `references/elicitation-engine.md` and `references/state-first-run.md` to a plain request routed by the
  skill guide.
- `.claude/skills/generate-profile/SKILL.md`: its curated-skill count no longer includes the triage
  router.
- Update the site scripts that know `aid-triage`: `site/scripts/skills/` (curated roster, groups, counts,
  index) and `site/scripts/gen-reference.mjs`. `aid-orchestrate` takes the first place in Support
  (Q134, D6). Regeneration removes `site/src/content/docs/skills/aid-triage.md` and
  `site/src/data/skill-flows/aid-triage.flow.json`.
- Delete `tests/canonical/test-triage-routing.sh`.
- Count re-sync (Q134, D5): the skill-count phrases in `README.md` and `docs/` take the derived count,
  and `sync:docs` runs. Change only the numbers.
- Suites to update in this same task:
  - the site tests that name `aid-triage`: `flow-classify`, `flow-extract-dispatch`, `flow-graph`,
    `gen-reference`, `gen-skills-index`, `skill-counts`, `skills-groups` and `skills-render-index` under
    `site/scripts/__tests__/`. Several of them read the real `aid-triage` body;
  - `tests/canonical/test-cutover-no-dangling.sh`;
  - `tests/canonical/test-deploy-monitor-repurpose.sh`, whose standalone list drops `aid-triage`;
  - `test-doc-counts.sh`;
  - any suite the findings' S1 or S6 assigns here.
- **Site regeneration.** Run `(cd site && npm run gen:skills && npm run gen:reference)` and commit its
  output: the skill pages, `skills/index.md`, `src/data/skill-flows/`, `reference/skills.md` and
  `scripts/.skills-manifest.json`. Never edit a generated site file by hand.
- **Same-task rule (Q106).** This task updates every suite that asserts text in a file it changes,
  including `site/scripts/__tests__/` and the dashboard tests. It is not `Done` while such a suite fails.
  - A removed assertion gets its row in `tests/coverage-accepted-removals.tsv`.
  - A renamed assertion gets its row in `tests/coverage-rehome-allowlist.tsv`.
  - The baselines themselves are re-recorded at the gate (Q134, D11).
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-001-sites.md` assigns to `task-009`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `task-009: In Progress` commit. Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-009`.
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
     - Run `(cd site && npm test)` when this task changes `canonical/skills/`,
       `canonical/aid/templates/shortcut-catalog.yml`, `docs/` or `site/`. Run `npm ci` there first if
       `site/node_modules` is absent.
     - Run `python3 -m pytest <file>` for each dashboard test file this task changes.
  6. **Report.** For each suite, report where it ran, its result and its run count.
     - Ceiling (T5): one full run of steps 2-5 per test round. Between rounds, re-run only the failing
       group (T6).
     - The same failure after three fix rounds goes to the maintainer.

**Acceptance Criteria:**
- [ ] `test -e canonical/skills/aid-triage` fails. `git grep -n -E 'aid-triage|triage router' -- canonical/ .claude/skills/generate-profile/ site/scripts/ tests/canonical/` finds no line outside the findings' history class (AC-6: no front-door skill).
- [ ] `tests/canonical/test-triage-routing.sh` is gone, and each of its assertion ids in `tests/coverage-baseline.tsv` has a row in `tests/coverage-accepted-removals.tsv`.
- [ ] `site/src/content/docs/skills/aid-triage.md` and `site/src/data/skill-flows/aid-triage.flow.json` are absent, `aid-orchestrate` is the first member of the Support group, and the site `npm test` passes.
- [ ] `test-cutover-no-dangling.sh` and `test-deploy-monitor-repurpose.sh` pass in the scratch copy, and `test-doc-counts.sh` passes live.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
