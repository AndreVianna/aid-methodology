# task-327: Format 6: the doorway rows, inside legacy-skill-names markers

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 327 --field State.

**Type:** IMPLEMENT

**Source:** feature-009-one-skill-per-need -> delivery-012 -> AC-25, AC-31

**Depends on:** task-326

**Scope:**
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
  `.aid/works/work-003-full-aid-restructure/research/delivery-012-sites.md` assigns to `task-327`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-327.base`, which `/aid-execute` BUILD records on the
  first round). Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-327`.
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
- [ ] On a scratch repository at format 6, an `aid-create-api` work at `Specify` with no record gets `/aid-specify` with `kind: api`, and a second run changes nothing; under `pwsh` the twin gives byte-identical files.
- [ ] Every line of the step in `bin/aid` and `bin/aid.ps1` that names a retired skill lies between `legacy-skill-names: begin` and `end`; `test-aid-cli-parity.sh` passes in the scratch copy, `test-ps51-compat.sh` and `test-ascii-only.sh` where the test step puts them, and the new `Test-AidInstaller.ps1` case passes under `pwsh` locally (5.1 runs in the Windows lane at G0).
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
