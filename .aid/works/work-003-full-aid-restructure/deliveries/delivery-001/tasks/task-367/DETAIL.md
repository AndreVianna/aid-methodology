# task-367: Plain-request routing through aid-orchestrate, and the wording that holds it

> Execution protocol (unchanged): write the task's State as it changes -- In Progress, In Review,
> Done / Failed -- through writeback-state.sh --task-id 367 --field State.

**Type:** IMPLEMENT

**Source:** feature-001-plain-language-requests -> delivery-001 -> AC-1, AC-5, AC-7, AC-14, AC-29 (Q147 diagnosis RC-1, RC-2, RC-3, RC-5; Q148)

**Depends on:** task-018

**Scope:**
- `canonical/aid/rules.md` `## Handling a request` and `## Skill guide` (`.aid/works/work-003-full-aid-restructure/analysis/delivery-001-sample-diagnosis.md` § 3 fixes 8 and 9): reword, staying within the 20-line limit, so the section says propose-then-stop, small work runs `lite` and never by hand, every changing or work-lifecycle request goes through `/aid-orchestrate` first, what a Knowledge Base conflict is, what closes a work, and that a brought-in source is added to `sources:` before it is applied. The `/aid-orchestrate` guide line names start, resume, close and cancel.
- `canonical/skills/aid-orchestrate/SKILL.md` and its references (fixes 9 and 10; REQUIREMENTS.md § 11 Feature 001 `##### 2. Orchestration flow`, routing rule as amended by Q148): description names close; step order is check the reading, offer Preparation, size and show the reading, then hand an action-skill reading over, with `intent:` written into the work its START creates; a Close step points to `references/size-and-route.md` § 3 and sets `phase`. Make `start-or-resume.md`, `size-and-route.md` and `check-intent.md` agree with that one order. Keep SKILL.md within 80 lines and each reference within 120.
- `canonical/skills/aid-brainstorm/SKILL.md` INTAKE (fix 11): the seed name is stated in the same message as the first question about the idea, not asked on its own.
- `canonical/aid/templates/shortcut-engine.md` and `canonical/skills/aid-deploy/SKILL.md` START (fix 12): one line each, size never skips a step of the workflow.
- Suites that read a changed file are updated in this same task (Q106); regenerate the site (`gen:skills`, `gen:reference`, `sync:docs`).
- **Test step** (PLAN.md § "Testing before the resync"; the same in every task of this delivery).
  `BASE` is this task's `base` (`tasks_lifecycle.task-367.base`, which `/aid-execute` BUILD records on the
  first round). Work in the `work-003` worktree only, create no
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
     - Make the copy exactly as PLAN.md § "How the copy is made" says, with `S=.aid/.temp/scratch/task-367`.
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
- [ ] `## Handling a request` stays within 20 lines (SG-01) and states: propose in one line, then change no project file until the user agrees, however small; small work runs `lite`, never by hand outside its workflow; every request that changes the project or starts, resumes, closes or cancels a work goes through `/aid-orchestrate` first; what a Knowledge Base conflict is; what closes a work; and that a source brought in is added to the work's `sources:` before it is applied.
- [ ] `aid-orchestrate`'s description and its skill-guide line name start, resume, close and cancel; its steps check the reading, offer Preparation when there is no Knowledge Base, size and show the reading, and only then hand an action-skill reading over, with `intent:` written into the work its START creates (REQUIREMENTS.md Feature 001 routing rule as amended); a Close step points to `size-and-route.md` § 3 and sets `phase` too. No reference contradicts that order.
- [ ] `aid-brainstorm` INTAKE names the seed in the same message as the first question about the idea; `shortcut-engine.md` and `aid-deploy` state that size never skips a step of the workflow.
- [ ] `test-skill-guide.sh` passes live; every suite that reads a changed file is updated in this task and passes; the site is regenerated and `(cd site && npm test)` passes.
- [ ] The test step (last Scope bullet) reports no failure: the spawn-free checks, the scratch half, the live half and the site or dashboard runs it calls for. Every existing test still passes.
- [ ] All section-6 quality gates pass (REQUIREMENTS.md § 6: NFR-N, NFR-T, NFR-Q).
