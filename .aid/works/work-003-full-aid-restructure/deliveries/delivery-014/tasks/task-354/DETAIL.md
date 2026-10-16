# task-354: The pre-release name check: retired-names.txt and test-doc-names.sh

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 354 --field State.

**Type:** TEST

**Source:** feature-009-one-skill-per-need -> delivery-014 -> AC-24, AC-45

**Depends on:** task-353

**Scope:**
- Create `tests/canonical/retired-names.txt` (REQUIREMENTS.md § 11 Feature 009 `##### 9. Testing`, Pre-release check): every retired slash name,
  one per line, kept equal to the old -> new table of `.aid/knowledge/backlog.md` § Next Release (the findings' D2).
- Create `tests/canonical/test-doc-names.sh`, a bash harness on `tests/lib/assert.sh` with `# COVERS:` lines and a
  group filter:
  - **DN-01**: with `AID_RELEASE_CHECK=1`, no file under `docs/`, `site/src/content/` or `examples/`, nor `README.md`,
    names a name of `retired-names.txt` as `/aid-<name>` or in backticks, nor an old phase name as a phase (in a `->`
    or `→` sequence, or followed by "phase"); text between `legacy-skill-names` markers is skipped. Without the flag
    it prints the hits and passes;
  - **DN-02**: no name of `retired-names.txt` is a folder under `canonical/skills/`; with the flag, each has a row in
    the old -> new table of `backlog.md` § Next Release;
  - **DN-03**: with the flag, every file the identity search finds carries "software first, not software only", and
    the same search, with its test-folder exclusions, finds "kind of digital work" in no file. Without the flag it
    prints those hits and passes, as DN-01 does, so tasks 356-361 can check their own files before the gate.
- **Findings.** This task's scope also includes every site that
  `.aid/works/work-003-full-aid-restructure/research/delivery-014-sites.md` assigns to `task-354`.
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-354.base`, which `/aid-execute` BUILD records on the
  first round). Work in the `work-003` worktree only, create no
  branch or worktree, and never run `run_generator.py` in the live tree.
  1. **Spawn-free checks (T2).** Run `bash -n` on each changed `.sh`, `python3 -m py_compile` on each
     changed `.py`, and `node --check` on each changed `.mjs`.
  2. **Selection.** `SEL` is the output of `bash tests/canonical/select-suites.sh --since "$BASE"`.
     `COPY` is the members of `SEL` whose text matches the pattern `P` of PLAN.md § "Testing before the
     resync", The driver. `LIVE` is `SEL` minus `COPY`. A change that lies wholly under `.aid/works/`
     selects nothing.
  3. **Scratch half** (when `COPY` is not empty).
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-354`.
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
- [ ] Without the flag the suite passes where the test step puts it and prints the hits the findings' D1 and D3 list; with `AID_RELEASE_CHECK=1` it fails on them, naming each file.
- [ ] Each check fails its own mutation in a scratch copy: `/aid-create-api` outside the markers in `README.md`; `Specify -> Plan` in a `docs/` page; a `canonical/skills/aid-design/` folder; a name with no `backlog.md` row; "kind of digital work" in `docs/faq.md`. Text between the markers is skipped.
- [ ] It is deterministic, reads files only, and finishes within the 300-second budget.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
