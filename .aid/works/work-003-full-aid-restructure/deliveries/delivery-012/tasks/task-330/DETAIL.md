# task-330: Migration cases: old doorway works

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 330 --field State.

**Type:** TEST

**Source:** feature-009-one-skill-per-need -> delivery-012 -> AC-25, AC-31, AC-37

**Depends on:** task-327

**Scope:**
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
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-330.base`, which `/aid-execute` BUILD records on the
  first round). Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-330`.
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
- [ ] The suite passes where the test step puts it, with each new case named.
- [ ] Moving one row outside the markers in a scratch copy fails the marker case; changing one byte of the PowerShell output fails the byte-identity case.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
